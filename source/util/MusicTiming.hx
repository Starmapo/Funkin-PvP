package util;

import data.Settings;
import data.song.TimingPoint;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import sprites.DancingSprite;

/**
	Handles time on a music object, plus step/beat hits, resyncing vocals, all that good stuff.

	Note that `curStep`, `curBeat` and `curBar` are all relative to the current timing section, not the whole song. This is due to the fact that timing points can be placed anywhere, unlike the original FNF where changing BPMs is limited to every 4 beats.
**/
class MusicTiming implements IFlxDestroyable
{
	/**
		How much the current time has to be behind or ahead of the music's time to resync it.
	**/
	public static final SYNC_THRESHOLD:Int = 16;

	/**
		How much time to wait before trying to sync the time to the music's time.
	**/
	public static final ROUTINE_SYNC_TIME:Int = 1000;

	/**
		The time in audio/play.
	**/
	public var time(default, null):Float = 0;

	/**
		Current audio position with user offsets applied.
	**/
	public var audioPosition(default, null):Float = 0;

	/**
		Whether the music has started playing.
	**/
	public var hasStarted(default, null):Bool = false;

	/**
		The callback for when the music starts playing.
	**/
	public var onStart:MusicTiming->Void;

	/**
		The list of timing points, used for calculating the current step.
	**/
	public var timingPoints:Array<TimingPoint> = [];

	/**
		The current timing point.
	**/
	public var curTimingPoint:TimingPoint;

	/**
		The current timing point index.
	**/
	public var curTimingIndex:Int;

	/**
		The current step of the current TIMING SECTION, not the whole song.
	**/
	public var curStep(get, never):Int;

	/**
		The current decimal step of the current TIMING SECTION, not the whole song.
	**/
	public var curDecStep(default, null):Float = -1;

	/**
		The current beat of the current TIMING SECTION, not the whole song.
	**/
	public var curBeat(get, never):Int;

	/**
		The current decimal beat of the current TIMING SECTION, not the whole song.
	**/
	public var curDecBeat(default, null):Float = -1;

	/**
		The current bar of the current TIMING SECTION, not the whole song.
	**/
	public var curBar(get, never):Int;

	/**
		The current decimal bar of the current TIMING SECTION, not the whole song.
	**/
	public var curDecBar(default, null):Float = -1;

	/**
		Gets dispatched when a new step is reached.
	**/
	public var onStepHit:FlxTypedSignal<Int->Float->Void> = new FlxTypedSignal();

	/**
		Gets dispatched when a new beat is reached.
	**/
	public var onBeatHit:FlxTypedSignal<Int->Float->Void> = new FlxTypedSignal();

	/**
		Whether or not this will detect if it missed a step hit and replay it before the current step.
	**/
	public var checkSkippedSteps:Bool = true;

	var music:FlxSound;
	var startDelay:Float;
	var extraMusic:Array<FlxSound>;
	var previousTime:Float = 0;
	var storedSteps:Array<Int> = [];
	var oldStep:Int = -1;
	var dancingSprites:Array<DancingSprite> = [];

	/**
		Creates a new timing object.
		@param music        The music to base the timing off of. Note that it should be pitched beforehand.
		@param timingPoints	The timing points to use for step/beat/bar calculations.
		@param startDelay   The time to wait before playing the music.
		@param extraMusic	Extra music objects to sync with the main music.
		@param onStart		A callback for when the music starts playing.
	**/
	public function new(music:FlxSound, ?timingPoints:Array<TimingPoint>, checkSkippedSteps:Bool = true, startDelay:Float = 0, ?onBeatHit:Int->Float->Void,
			?extraMusic:Array<FlxSound>, ?onStart:MusicTiming->Void)
	{
		if (music == null)
			music = new FlxSound();
		if (extraMusic == null)
			extraMusic = [];
		if (timingPoints == null)
			timingPoints = [];

		this.music = music;
		this.timingPoints = timingPoints;
		this.checkSkippedSteps = checkSkippedSteps;
		this.extraMusic = extraMusic;
		this.startDelay = startDelay;
		this.onStart = onStart;
		if (onBeatHit != null)
			this.onBeatHit.add(onBeatHit);

		if (music.playing)
		{
			hasStarted = true;
			time = music.time;
			resyncExtraMusic();
			updateAudioPosition();
			updateCurStep();
		}
		else
			time = -startDelay * music.pitch;
	}

	public function update(elapsed:Float)
	{
		if (music == null)
			return;

		if (time < 0)
		{
			time += elapsed * 1000 * music.pitch;
			return;
		}

		if (!hasStarted)
		{
			hasStarted = true;

			music.play(true, time);
			for (extra in extraMusic)
				extra.play(true, time);

			if (onStart != null)
				onStart(this);
		}

		updateTime();
		resyncExtraMusic();
		updateAudioPosition();
		updateCurStep();
	}

	public function destroy()
	{
		FlxDestroyUtil.destroy(onStepHit);
		FlxDestroyUtil.destroy(onBeatHit);
	}

	/**
		Forces the time to the new value.
	**/
	public function setTime(newTime:Float)
	{
		music.time = newTime;
		for (extra in extraMusic)
			extra.time = newTime;
		time = newTime;
		updateAudioPosition();
		updateCurStep();
	}

	/**
		Adds a dancing sprite to this object.
	**/
	public function addDancingSprite(sprite:DancingSprite)
	{
		dancingSprites.push(sprite);
	}

	/**
		Removes a dancing sprite from this object.
	**/
	public function removeDancingSprite(sprite:DancingSprite)
	{
		dancingSprites.remove(sprite);
	}

	/**
		Pauses all music.
	**/
	public function pauseMusic()
	{
		music.pause();
		for (extra in extraMusic)
		{
			extra.pause();
		}
	}

	/**
		Resumes all music.
	**/
	public function resumeMusic()
	{
		music.resume();
		for (extra in extraMusic)
		{
			extra.resume();
		}
	}

	/**
		Stops all music.
	**/
	public function stopMusic()
	{
		music.stop();
		for (extra in extraMusic)
		{
			extra.stop();
		}
		reset();
	}

	function updateTime()
	{
		if (Settings.smoothAudioTiming)
		{
			time += FlxG.elapsed * 1000 * music.pitch;

			var timeOutOfThreshold = time < music.time || time > music.time + (SYNC_THRESHOLD * music.pitch);
			var checkTime = music.time - previousTime;
			var needsRoutineSync = checkTime >= ROUTINE_SYNC_TIME || checkTime <= -ROUTINE_SYNC_TIME;

			if (!timeOutOfThreshold && !needsRoutineSync && previousTime != 0)
				return;

			previousTime = time = music.time;
		}
		else
		{
			time = music.time;
		}
	}

	function resyncExtraMusic()
	{
		if (!music.playing)
			return;

		for (extra in extraMusic)
		{
			if (!extra.playing)
				continue;

			var timeOutOfThreshold = Math.abs(extra.time - music.time) >= SYNC_THRESHOLD * music.pitch;
			if (timeOutOfThreshold)
			{
				FlxG.log.notice('Resynced vocals with difference of ' + Math.abs(extra.time - music.time));
				extra.time = music.time;
			}
		}
	}

	function updateAudioPosition()
	{
		audioPosition = time + Settings.globalOffset * music.pitch;

		FlxG.watch.addQuick('Song Time', audioPosition);
	}

	function updateCurStep()
	{
		if (timingPoints.length == 0)
		{
			curTimingPoint = null;
			curTimingIndex = 0;
			curDecStep = curDecBeat = curDecBar = -1;
			return;
		}

		curTimingIndex = timingPoints.length - 1;
		while (curTimingIndex >= 0)
		{
			if (audioPosition >= timingPoints[curTimingIndex].startTime)
				break;

			curTimingIndex--;
		}

		if (curTimingIndex < 0)
			curTimingIndex = 0;

		curTimingPoint = timingPoints[curTimingIndex];
		curDecStep = (audioPosition - curTimingPoint.startTime) / curTimingPoint.stepLength;
		curDecBeat = curDecStep / 4;
		curDecBar = curDecBeat / curTimingPoint.meter;

		// thx forever engine
		if (oldStep > curStep)
		{
			oldStep = curStep - 1;
		}
		for (i in storedSteps)
		{
			if (i < oldStep || i > curStep)
				storedSteps.remove(i);
		}
		if (checkSkippedSteps && curStep > oldStep)
		{
			for (i in oldStep...curStep)
			{
				if (!storedSteps.contains(i) && i >= 0)
				{
					stepHit(i, i);
				}
			}
		}

		if (curStep > oldStep && curStep >= 0 && !storedSteps.contains(curStep))
			stepHit(curStep, curDecStep);
		oldStep = curStep;

		FlxG.watch.addQuick('Current Step', curStep);
		FlxG.watch.addQuick('Current Beat', curBeat);
	}

	function stepHit(step:Int, decStep:Float)
	{
		onStepHit.dispatch(step, decStep);

		if (step % 4 == 0)
		{
			var decBeat = decStep / 4;
			beatHit(Math.floor(decBeat), decBeat);
		}

		if (!storedSteps.contains(step))
			storedSteps.push(step);
	}

	function beatHit(beat:Int, decBeat:Float)
	{
		for (sprite in dancingSprites)
		{
			if (beat % sprite.danceBeats == 0)
			{
				sprite.dance();
			}
		}

		onBeatHit.dispatch(beat, decBeat);
	}

	function reset()
	{
		time = 0;
		curTimingPoint = null;
		curTimingIndex = 0;
		curDecStep = curDecBeat = curDecBar = -1;
		oldStep = -1;
	}

	function get_curStep()
	{
		return Math.floor(curDecStep);
	}

	function get_curBeat()
	{
		return Math.floor(curDecBeat);
	}

	function get_curBar()
	{
		return Math.floor(curDecBar);
	}
}
