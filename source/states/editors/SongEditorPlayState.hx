package states.editors;

import data.song.Song;
import flixel.FlxG;
import flixel.sound.FlxSound;
import util.MusicTiming;

class SongEditorPlayState extends FNFState
{
	var song:Song;
	var originalSong:Song;
	var startTime:Float;
	var timing:MusicTiming;
	var inst:FlxSound;
	var vocals:FlxSound;

	public function new(map:Song, startTime:Float = 0)
	{
		super();
		song = map.deepClone();
		originalSong = map;
		this.startTime = startTime;

		var i = song.notes.length - 1;
		while (i >= 0)
		{
			var note = song.notes[i];
			if (note.startTime + 2 < startTime)
				song.notes.remove(note);
			i--;
		}

		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup);
		var vocalsSound = Paths.getSongVocals(song);
		if (vocalsSound != null)
			vocals = FlxG.sound.load(vocalsSound, 1, false, FlxG.sound.defaultMusicGroup);
		else
			vocals = new FlxSound();

		timing = new MusicTiming(inst, song.timingPoints, true, null, [vocals]);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);
	}
}
