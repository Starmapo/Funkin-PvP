package util;

import data.Settings;
import flixel.system.FlxSound;
import states.BasicPlayState;

class AudioTiming
{
	/**
		How much the current time has to be behind or ahead of the music's time.
	**/
	public static final SYNC_THRESHOLD:Int = 16;

	/**
		How much time to wait before trying to sync the time to the music's time.
	**/
	public static final ROUTINE_SYNC_TIME:Int = 1000;

	/**
		The time in audio/play.
	**/
	public var time:Float = 0;

	var state:BasicPlayState;
	var music:FlxSound;
	var startDelay:Int;
	var extraMusic:Array<FlxSound>;
	var previousTime:Float = 0;

	/**
		Creates a new timing object.
		@param music        The music to base the timing off of. Note that it should be pitched beforehand.
		@param startDelay   The time to wait before playing the music.
	**/
	public function new(state:BasicPlayState, music:FlxSound, ?extraMusic:Array<FlxSound>, startDelay:Int = 3000)
	{
		if (extraMusic == null)
			extraMusic = [];

		this.state = state;
		this.music = music;
		this.startDelay = startDelay;
		this.extraMusic = extraMusic;

		time = -startDelay;
	}

	public function update(elapsed:Float)
	{
		if (state.isPaused)
			return;

		if (time < 0)
		{
			time += elapsed * 1000 * music.pitch;

			if (time < 0)
				return;
		}

		if (!state.hasStarted)
		{
			music.play(true, time);
			for (extra in extraMusic)
			{
				extra.play(true, time);
			}
			state.startSong();
		}

		if (Settings.smoothAudioTiming)
		{
			time += elapsed * 1000 * music.pitch;

			if (!music.playing)
				return;

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
			if (music.playing)
				time = music.time;
			else
				time += elapsed * 1000 * music.pitch;

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
	}

	function resyncExtraMusic()
	{
		if (!music.playing)
			return;

		for (extra in extraMusic)
		{
			if (!extra.playing)
				continue;

			var timeOutOfThreshold = extra.time < music.time || extra.time > music.time + (SYNC_THRESHOLD * music.pitch);
			if (timeOutOfThreshold)
			{
				extra.time = music.time;
			}
		}
	}
}
