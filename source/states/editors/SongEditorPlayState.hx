package states.editors;

import data.game.GameplayRuleset;
import data.game.Judgement;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import ui.game.JudgementDisplay;
import ui.game.LyricsDisplay;
import ui.game.Note;
import ui.game.PlayerStatsDisplay;
import ui.game.SongInfoDisplay;
import util.DiscordClient;
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
	var statsDisplay:FlxTypedGroup<PlayerStatsDisplay>;
	var judgementDisplay:FlxTypedGroup<JudgementDisplay>;
	var songInfoDisplay:SongInfoDisplay;
	var lyricsDisplay:LyricsDisplay;

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
	}

	override function destroy()
	{
		super.destroy();
		song = FlxDestroyUtil.destroy(song);
		originalSong = null;
		timing = FlxDestroyUtil.destroy(timing);
		inst = null;
		vocals = FlxDestroyUtil.destroy(vocals);
		ruleset = FlxDestroyUtil.destroy(ruleset);
		bg = null;
		statsDisplay = null;
		judgementDisplay = null;
		songInfoDisplay = null;
		lyricsDisplay = null;
	}

	override function create()
	{
		DiscordClient.changePresence(song.title + ' [${song.difficultyName}]', "Song Editor Playtesting");

		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup);
		inst.onComplete = onSongComplete;
		var vocalsSound = Paths.getSongVocals(song);
		if (vocalsSound != null)
			vocals = FlxG.sound.load(vocalsSound, 1, false, FlxG.sound.defaultMusicGroup);
		else
			vocals = new FlxSound();

		timing = new MusicTiming(inst, song.timingPoints, false, startDelay, null, [vocals]);
		final delay = 500;
		if (startTime < startDelay)
			timing.setTime(startTime <= 500 ? -1500 : -delay);
		else
			timing.setTime(FlxMath.bound(startTime - delay, 0, inst.length));

		bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);

		ruleset = new GameplayRuleset(song, timing);
		if (player == 0)
			ruleset.inputManagers[1].autoplay = true;
		else
		{
			ruleset.inputManagers[0].autoplay = true;
			ruleset.inputManagers[1].changePlayer(0);
		}
		for (playfield in ruleset.playfields)
			add(playfield);
		for (manager in ruleset.noteManagers)
			add(manager);

		ruleset.lanePressed.add(onLanePressed);
		ruleset.laneReleased.add(onLaneReleased);
		ruleset.noteHit.add(onNoteHit);
		ruleset.judgementAdded.add(onJudgementAdded);

		judgementDisplay = new FlxTypedGroup();
		for (i in 0...2)
			judgementDisplay.add(new JudgementDisplay(i, ruleset.playfields[i].noteSkin));
		add(judgementDisplay);

		statsDisplay = new FlxTypedGroup();
		for (i in 0...2)
			statsDisplay.add(new PlayerStatsDisplay(ruleset.scoreProcessors[i]));
		add(statsDisplay);

		songInfoDisplay = new SongInfoDisplay(song, inst, timing);
		add(songInfoDisplay);

		lyricsDisplay = new LyricsDisplay(song, Song.getSongLyrics(song));
		add(lyricsDisplay);

		super.create();
	}

	override function update(elapsed:Float)
	{
		timing.update(elapsed);

		ruleset.updateCurrentTrackPosition();

		handleInput(elapsed);

		ruleset.update(elapsed);
		judgementDisplay.update(elapsed);
		statsDisplay.update(elapsed);
		songInfoDisplay.update(elapsed);
		lyricsDisplay.updateLyrics(timing.audioPosition);

		if (FlxG.mouse.visible)
			FlxG.mouse.visible = false;
	}

	function handleInput(elapsed:Float)
	{
		if (isPaused)
			return;

		if (!isPlayComplete)
		{
			if (FlxG.keys.justPressed.ESCAPE)
				exit();

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
			for (bind in inputManager.bindingStore)
				bind.pressed = false;
		}
	}

	function onSongComplete()
	{
		lyricsDisplay.visible = false;
		exit();
	}

	function exit()
	{
		inst.stop();
		vocals.stop();
		persistentUpdate = false;
		FlxG.switchState(new SongEditorState(originalSong));
	}

	function onLanePressed(lane:Int, player:Int)
	{
		ruleset.playfields[player].onLanePressed(lane);
	}

	function onLaneReleased(lane:Int, player:Int)
	{
		ruleset.playfields[player].onLaneReleased(lane);
	}

	function onNoteHit(note:Note, judgement:Judgement)
	{
		var player = note.info.player;
		ruleset.playfields[player].onNoteHit(note, judgement);
	}

	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		judgementDisplay.members[player].showJudgement(judgement);
	}
}
