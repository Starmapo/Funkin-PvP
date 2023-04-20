package ui.game;

import data.song.Song;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;

class SongInfoDisplay extends FlxText
{
	var song:Song;
	var inst:FlxSound;
	var length:String;

	public function new(song:Song, inst:FlxSound)
	{
		super();
		this.song = song;
		this.inst = inst;
		length = FlxStringUtil.formatTime((inst.length / 1000) / inst.pitch);

		fieldWidth = FlxG.width - 10;
		setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxColor.BLACK);
		x = 5;
	}

	override function update(elapsed:Float)
	{
		var newText = song.title
			+ ' ['
			+ song.difficultyName
			+ ']\n'
			+ song.source
			+ '\n'
			+ FlxStringUtil.formatTime((inst.time / 1000) / inst.pitch)
			+ ' / '
			+ length;
		if (text != newText)
			text = newText;
	}
}
