package util;

import data.Settings;
import flixel.FlxG;
import flixel.sound.FlxSound;

class MusicTiming
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
		Whether the music has started playing.
	**/
	public var hasStarted(default, null):Bool = false;

	/**
		The callback for when the music starts playing.
	**/
	public var onStart:MusicTiming->Void;

	var music:FlxSound;
	var startDelay:Int;
	var extraMusic:Array<FlxSound>;
	var previousTime:Float = 0;

	/**
		Creates a new timing object.
		@param music        The music to base the timing off of. Note that it should be pitched beforehand.
		@param extraMusic	Extra music objects to sync with the main music.
		@param startDelay   The time to wait before playing the music.
		@param onStart		A callback for when the music starts playing.
	**/
	public function new(music:FlxSound, ?extraMusic:Array<FlxSound>, startDelay:Int = 0, ?onStart:MusicTiming->Void)
	{
		if (music == null)
			music = new FlxSound();
		if (extraMusic == null)
			extraMusic = [];

		this.music = music;
		this.startDelay = startDelay;
		this.extraMusic = extraMusic;
		this.onStart = onStart;

		time = -startDelay * music.pitch;
	}

	public function update(elapsed:Float)
	{
		if (music == null)
			return;

		if (time >= 0 && !music.playing)
			return;

		if (time < 0)
		{
			time += elapsed * 1000 * music.pitch;
			return;
		}

		if (!hasStarted)
		{
			hasStarted = true;

			if (!music.playing)
				music.play(true, time);

			for (extra in extraMusic)
			{
				if (!extra.playing)
					extra.play(true, time);
			}

			if (onStart != null)
				onStart(this);
		}

		if (Settings.smoothAudioTiming)
		{
			time += elapsed * 1000 * music.pitch;

			resyncExtraMusic();

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
			resyncExtraMusic();
		}
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
		time = 0;
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
				FlxG.log.add('Resynced vocals with difference of ' + Math.abs(extra.time - music.time));
				extra.time = music.time;
			}
		}
	}
}
