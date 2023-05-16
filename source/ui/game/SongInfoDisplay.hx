package ui.game;

import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import util.MusicTiming;

class SongInfoDisplay extends FlxText
{
	var song:Song;
	var inst:FlxSound;
	var length:Float;
	var lengthDisplay:String;
	var timing:MusicTiming;

	public function new(song:Song, inst:FlxSound, timing:MusicTiming)
	{
		super();
		this.song = song;
		this.inst = inst;
		this.timing = timing;
		length = inst.length - Settings.globalOffset * inst.pitch;
		lengthDisplay = FlxStringUtil.formatTime((length / 1000) / inst.pitch);

		fieldWidth = FlxG.width - 10;
		setFormat('VCR OSD Mono', (Settings.hideHUD ? 32 : 16), FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		x = 5;
	}

	override function update(elapsed:Float)
	{
		var prefix = !Settings.hideHUD ? (song.artist + ' - ' + song.title + ' [' + song.difficultyName + ']\n' + song.source + '\n') : '';
		var pos = Math.max(timing.audioPosition, 0);
		var timeText = switch (Settings.timeDisplay)
		{
			case TIME_ELAPSED:
				FlxStringUtil.formatTime((pos / 1000) / inst.pitch) + ' / ' + lengthDisplay;
			case TIME_LEFT:
				FlxStringUtil.formatTime(((length - pos) / 1000) / inst.pitch);
			case PERCENTAGE:
				Math.floor((pos / length) * 100) + '%';
			default:
				'';
		}
		var newText = prefix + timeText;
		if (text != newText)
			text = newText;
	}

	override function destroy()
	{
		super.destroy();
		song = null;
		inst = null;
		timing = null;
	}
}
