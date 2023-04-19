package states.editors;

import data.game.GameplayRuleset;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import util.MusicTiming;

class SongEditorPlayState extends FNFState
{
	var song:Song;
	var originalSong:Song;
	var player:Int;
	var startTime:Float;
	var timing:MusicTiming;
	var inst:FlxSound;
	var vocals:FlxSound;
	var ruleset:GameplayRuleset;
	var startDelay:Int = 3000;
	var isPaused:Bool = false;
	var isPlayComplete:Bool = false;
	var bg:FlxSprite;

	public function new(map:Song, player:Int, startTime:Float = 0)
	{
		super();
		song = map.deepClone();
		originalSong = map;
		this.player = player;
		this.startTime = startTime;

		persistentUpdate = true;

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

		timing = new MusicTiming(inst, song.timingPoints, false, startDelay, null, [vocals]);

		bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);

		ruleset = new GameplayRuleset(song, timing);
	}

	override function update(elapsed:Float)
	{
		timing.update(elapsed);

		handleInput(elapsed);

		ruleset.update();
	}

	override function draw()
	{
		bg.draw();
		for (playfield in ruleset.playfields)
			playfield.draw();
		for (manager in ruleset.noteManagers)
			manager.draw();
	}

	function handleInput(elapsed:Float)
	{
		if (isPaused)
			return;

		if (!isPlayComplete)
		{
			if (FlxG.keys.justPressed.F2)
			{
				if (inst.playing)
					inst.pause();

				FlxG.switchState(new SongEditorState(originalSong));
			}

			handleAutoplayInput();
		}

		ruleset.handleInput(elapsed);
	}

	function handleAutoplayInput()
	{
		if (FlxG.keys.justPressed.TAB)
		{
			var inputManager = ruleset.inputManagers[player];
			inputManager.autoplay = !inputManager.autoplay;
		}
	}
}
