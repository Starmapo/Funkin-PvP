package backend;

import backend.structures.song.TimingPoint;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import objects.DancingSprite;

/**
	Handles time on a music object, plus step/beat hits, resyncing vocals, all that good stuff.

	Note that `curStep`, `curBeat` and `curBar` are all relative to the current timing section, not the whole song.
	This is due to the fact that timing points can be placed anywhere, unlike the original FNF where changing BPMs is
	limited to every 4 beats.
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
		Gets dispatched when a new bar is reached.
	**/
	public var onBarHit:FlxTypedSignal<Int->Float->Void> = new FlxTypedSignal();
	
	/**
		Whether or not this should do step/beat/bar hits.
	**/
	public var doStepHits:Bool = true;
	
	/**
		Whether or not this will detect if it missed a step hit and replay it before the current step.
	**/
	public var checkSkippedSteps:Bool;
	
	/**
		Whether or not to make sprites dance when a beat is hit.
	**/
	public var dance:Bool = true;
	
	/**
		Whether or not the timing is paused.
	**/
	public var paused:Bool = false;
	
	var music:FlxSound;
	var extraMusic:Array<FlxSound>;
	var previousTime:Float = 0;
	var storedSteps:Array<Int> = [];
	var oldStep:Int = -1;
	var dancingSprites:Array<DancingSprite> = [];
	var initialized:Bool = false;
	
	public function new(music:FlxSound, timingPoints:Array<TimingPoint>, checkSkippedSteps:Bool = false, startDelay:Float = 0, ?onBeatHit:Int->Float->Void,
			?extraMusic:Array<FlxSound>, ?onStart:MusicTiming->Void)
	{
		if (timingPoints == null || timingPoints.length < 1)
			throw "You must have at least 1 timing point for a song";
		if (music == null)
			music = new FlxSound();
		if (extraMusic == null)
			extraMusic = [];
			
		this.music = music;
		this.timingPoints = timingPoints;
		this.checkSkippedSteps = checkSkippedSteps;
		this.extraMusic = extraMusic;
		this.onStart = onStart;
		if (onBeatHit != null)
			this.onBeatHit.add(onBeatHit);
			
		time = -startDelay * music.pitch;
		updateTimeStuff();
		initialized = true;
		hasStarted = music.playing;
	}
	
	public function update(elapsed:Float)
	{
		if (music == null)
			return;
			
		if (time < 0)
		{
			time += elapsed * 1000 * music.pitch;
			updateTimeStuff();
			
			if (time < 0)
				return;
		}
		
		updateTime(elapsed);
		
		if (!hasStarted)
		{
			hasStarted = true;
			
			music.play(true, time);
			for (extra in extraMusic)
				extra.play(true, time);
				
			if (onStart != null)
				onStart(this);
		}
		
		resyncExtraMusic();
		updateTimeStuff();
	}
	
	public function destroy()
	{
		onStart = null;
		timingPoints = null;
		curTimingPoint = null;
		FlxDestroyUtil.destroy(onStepHit);
		FlxDestroyUtil.destroy(onBeatHit);
		FlxDestroyUtil.destroy(onBarHit);
		music = null;
		extraMusic = null;
		storedSteps = null;
		dancingSprites = null;
	}
	
	/**
		Forces the time to the new value.
	**/
	public function setTime(newTime:Float)
	{
		time = newTime;
		music.time = newTime;
		for (extra in extraMusic)
			extra.time = newTime;
		updateTimeStuff();
	}
	
	/**
		Adds a dancing sprite to this object.
	**/
	public function addDancingSprite(sprite:DancingSprite)
	{
		if (sprite != null && !dancingSprites.contains(sprite))
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
		Plays all music.
	**/
	public function playMusic()
	{
		music.play();
		for (extra in extraMusic)
			extra.play();
		doStepHits = true;
		paused = false;
		time = music.time;
		updateTimeStuff();
	}
	
	/**
		Pauses all music.
	**/
	public function pauseMusic()
	{
		music.pause();
		for (extra in extraMusic)
			extra.pause();
		paused = true;
	}
	
	/**
		Resumes all music.
	**/
	public function resumeMusic()
	{
		music.resume();
		for (extra in extraMusic)
			extra.resume();
		paused = false;
	}
	
	/**
		Stops all music.
	**/
	public function stopMusic()
	{
		music.stop();
		for (extra in extraMusic)
			extra.stop();
		doStepHits = false;
		reset();
		paused = false;
	}
	
	function updateTime(elapsed:Float)
	{
		@:privateAccess
		if (music._paused || paused)
			return;
			
		time += elapsed * 1000 * music.pitch;
		
		if (!music.playing)
			return;
			
		var threshold = (SYNC_THRESHOLD * music.pitch);
		var timeOutOfThreshold = time < music.time - threshold || time > music.time + threshold;
		if (!timeOutOfThreshold && previousTime != 0)
			return;
			
		previousTime = time = music.time;
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
				extra.time = music.time;
		}
	}
	
	function updateAudioPosition()
	{
		audioPosition = time + Settings.globalOffset;
		
		FlxG.watch.addQuick('Song Playing', music.playing);
		FlxG.watch.addQuick('Song Time', music.time);
		FlxG.watch.addQuick('Audio Position', audioPosition);
	}
	
	function updateCurStep()
	{
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
			oldStep = curStep - 1;
		var i = storedSteps.length - 1;
		while (i >= 0)
		{
			var step = storedSteps[i];
			if (step < oldStep || step > curStep)
				storedSteps.remove(step);
				
			i--;
		}
		
		if (initialized)
		{
			if (checkSkippedSteps && curStep > oldStep)
			{
				for (i in oldStep...curStep)
				{
					if (!storedSteps.contains(i) && i >= 0)
						stepHit(i, i);
				}
			}
			if (curStep > oldStep && curStep >= 0 && !storedSteps.contains(curStep))
				stepHit(curStep, curDecStep);
		}
		
		oldStep = curStep;
		
		FlxG.watch.addQuick('Current Step', curStep);
		FlxG.watch.addQuick('Current Beat', curBeat);
	}
	
	function stepHit(step:Int, decStep:Float)
	{
		if (!doStepHits)
			return;
			
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
		if (!doStepHits)
			return;
			
		if (dance)
		{
			for (sprite in dancingSprites)
			{
				if (sprite.exists && sprite.canDance && beat % sprite.danceBeats == 0)
					sprite.dance();
			}
		}
		
		onBeatHit.dispatch(beat, decBeat);
		
		if (beat % curTimingPoint.meter == 0)
		{
			var decBar = decBeat / curTimingPoint.meter;
			barHit(Math.floor(decBar), decBar);
		}
	}
	
	function barHit(bar:Int, decBar:Float)
	{
		if (!doStepHits)
			return;
			
		onBarHit.dispatch(bar, decBar);
	}
	
	function reset()
	{
		time = 0;
		updateTimeStuff();
	}
	
	function updateTimeStuff()
	{
		updateAudioPosition();
		updateCurStep();
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
