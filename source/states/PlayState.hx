package states;

import data.game.GameplayRuleset;
import data.game.Judgement;
import data.skin.NoteSkin;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import states.pvp.SongSelectState;
import ui.game.JudgementDisplay;
import ui.game.LyricsDisplay;
import ui.game.Note;
import ui.game.PlayerStatsDisplay;
import ui.game.Playfield;
import ui.game.SongInfoDisplay;
import util.MusicTiming;

class PlayState extends FNFState
{
	public var song:Song;
	public var isPaused:Bool = false;
	public var hasStarted:Bool = false;

	var camHUD:FlxCamera;
	var timing:MusicTiming;
	var songInst:FlxSound;
	var songVocals:FlxSound;
	var ruleset:GameplayRuleset;
	var statsDisplay:FlxTypedGroup<PlayerStatsDisplay>;
	var judgementDisplay:FlxTypedGroup<JudgementDisplay>;
	var songInfoDisplay:SongInfoDisplay;
	var lyricsDisplay:LyricsDisplay;

	public function new(?song:Song)
	{
		super();
		if (song == null)
			song = Song.loadSong('mods/fnf/songs/Tutorial/Hard');
		this.song = song;

		persistentUpdate = true;
	}

	override public function create()
	{
		if (FlxG.sound.musicPlaying)
			FlxG.sound.music.stop();

		initCameras();
		initSong();
		initUI();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		timing.update(elapsed);

		ruleset.updateCurrentTrackPosition();
		ruleset.update(elapsed);

		handleInput(elapsed);

		super.update(elapsed);

		lyricsDisplay.updateLyrics(songInst.time);
	}

	override function destroy()
	{
		super.destroy();
		timing = FlxDestroyUtil.destroy(timing);
	}

	public function startSong(timing:MusicTiming) {}

	public function exit()
	{
		timing.stopMusic();
		persistentUpdate = false;
		FlxG.switchState(new SongSelectState());
	}

	function initCameras()
	{
		FlxG.camera.bgColor = FlxColor.GRAY;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
	}

	function initSong()
	{
		songInst = FlxG.sound.load(Paths.getSongInst(song));
		songInst.onComplete = endSong;
		var vocals = Paths.getSongVocals(song);
		if (vocals != null)
			songVocals = FlxG.sound.load(vocals);
		else
			songVocals = FlxG.sound.list.add(new FlxSound());

		timing = new MusicTiming(songInst, song.timingPoints, true, song.timingPoints[0].beatLength * 5, [songVocals], startSong);
	}

	function initUI()
	{
		ruleset = new GameplayRuleset(song, timing);
		for (playfield in ruleset.playfields)
		{
			playfield.cameras = [camHUD];
			add(playfield);
		}
		for (manager in ruleset.noteManagers)
		{
			manager.cameras = [camHUD];
			add(manager);
		}

		ruleset.lanePressed.add(onLanePressed);
		ruleset.laneReleased.add(onLaneReleased);
		ruleset.noteHit.add(onNoteHit);
		ruleset.judgementAdded.add(onJudgementAdded);

		judgementDisplay = new FlxTypedGroup();
		for (i in 0...2)
			judgementDisplay.add(new JudgementDisplay(i, ruleset.playfields[i].noteSkin));
		judgementDisplay.cameras = [camHUD];
		add(judgementDisplay);

		statsDisplay = new FlxTypedGroup();
		for (i in 0...2)
			statsDisplay.add(new PlayerStatsDisplay(i, ruleset.scoreProcessors[i]));
		statsDisplay.cameras = [camHUD];
		add(statsDisplay);

		songInfoDisplay = new SongInfoDisplay(song, songInst);
		songInfoDisplay.cameras = [camHUD];
		add(songInfoDisplay);

		lyricsDisplay = new LyricsDisplay(song, Song.getSongLyrics(song));
		lyricsDisplay.cameras = [camHUD];
		add(lyricsDisplay);
	}

	function handleInput(elapsed:Float)
	{
		if (isPaused)
			return;

		ruleset.handleInput(elapsed);
	}

	function endSong()
	{
		lyricsDisplay.visible = false;
		exit();
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
