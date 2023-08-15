package backend;

import flixel.FlxG;
import flixel.FlxState;
import flixel.sound.FlxSound;
import lime.media.AudioManager;
import openfl.media.Sound;

/**
 * if youre stealing this keep this comment at least please lol
 *
 * hi gray itsa me yoshicrafter29 i fixed it hehe
 */
@:dox(hide)
class AudioSwitchFix
{
	@:noCompletion
	private static function onStateSwitch(state:FlxState):Void
	{
		#if windows
		if (Main.audioDisconnected)
		{
			var playingList:Array<PlayingSound> = [];
			for (e in FlxG.sound.list)
			{
				if (e != null && e.playing)
				{
					playingList.push({
						sound: e,
						time: e.time
					});
					e.stop();
				}
			}
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				playingList.push({
					sound: FlxG.sound.music,
					time: FlxG.sound.music.time
				});
				FlxG.sound.music.stop();
			}
			
			AudioManager.shutdown();
			AudioManager.init();
			Sound.curChangeID++;
			
			for (e in playingList)
				e.sound.play(e.time);
				
			Main.audioDisconnected = false;
		}
		#end
	}
	
	public static function init()
	{
		#if windows
		WindowsAPI.registerAudio();
		FlxG.signals.preStateCreate.add(onStateSwitch);
		#end
	}
}

typedef PlayingSound =
{
	var sound:FlxSound;
	var time:Float;
}
