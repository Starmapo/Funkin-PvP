package backend;

import flixel.FlxG;
import openfl.media.Sound;
import sys.thread.Mutex;
import sys.thread.Thread;

class Music
{
	public static var playing(get, never):Bool;
	
	static var pvpMusicThread:Thread;
	static var pvpMusicThreadActive:Bool = false;
	static var mutex:Mutex = new Mutex();
	static var pvpMusic:Sound;
	static var fadeInDuration:Float;
	
	/**
		Plays the menu music.

		@param	volume	The volume that the music should start at. Defaults to `1`, or full volume.
	**/
	public static function playMenuMusic(fadeInDuration:Float = 0):Void
	{
		pvpMusicThreadActive = false;
		playMusic(Paths.getMusic("Gettin' Freaky"), fadeInDuration);
	}
	
	/**
		Plays the PvP menu music.

		@param	fadeInDuration	The amount in seconds that it should take for the music to fade in.
								If it's `0` or below, it will start at max volume instead of fading in.
	**/
	public static function playPvPMusic(fadeInDuration:Float = 0):Void
	{
		if (Mods.pvpMusic.length < 1)
		{
			if (FlxG.sound.music == null || !FlxG.sound.music.playing)
				playMenuMusic();
				
			return;
		}
		
		if (pvpMusicThread != null)
			return;
			
		Music.fadeInDuration = fadeInDuration;
		
		stopMusic();
		
		var music = Mods.pvpMusic[FlxG.random.int(0, Mods.pvpMusic.length - 1)];
		
		pvpMusicThreadActive = true;
		pvpMusicThread = Thread.create(function()
		{
			var audio = Paths.getMusic(music.name, music.mod);
			
			mutex.acquire();
			pvpMusic = audio;
			pvpMusicThread = null;
			mutex.release();
		});
		
		FlxG.signals.postUpdate.add(pvpMusic_update);
	}
	
	public static function stopMusic()
	{
		pvpMusicThreadActive = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}
	
	static function pvpMusic_update()
	{
		mutex.acquire();
		if (pvpMusic != null)
		{
			if (pvpMusicThreadActive && !playing)
				playMusic(pvpMusic, fadeInDuration);
				
			pvpMusic = null;
			pvpMusicThreadActive = false;
			
			FlxG.signals.postUpdate.remove(pvpMusic_update);
		}
		mutex.release();
	}
	
	static function playMusic(music:Sound, fadeInDuration:Float)
	{
		FlxG.sound.playMusic(music, fadeInDuration > 0 ? 0 : 1);
		
		if (fadeInDuration > 0)
			FlxG.sound.music.fadeIn(fadeInDuration);
	}
	
	static function get_playing()
	{
		return FlxG.sound.music?.playing ?? false;
	}
}
