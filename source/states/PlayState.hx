package states;

import data.Mods;
import data.PlayerSettings;
import data.char.CharacterInfo;
import data.game.GameplayRuleset;
import data.game.Judgement;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import sprites.game.Character;
import states.pvp.SongSelectState;
import subStates.PauseSubState;
import ui.game.JudgementDisplay;
import ui.game.LyricsDisplay;
import ui.game.Note;
import ui.game.PlayerStatsDisplay;
import ui.game.SongInfoDisplay;
import util.MusicTiming;

class PlayState extends FNFState
{
	public var song:Song;
	public var chars:Array<String>;
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
	var pauseSubState:PauseSubState;
	var introSprPaths:Array<String> = ["ready", "set", "go"];
	var introSndPaths:Array<String> = [
		"intro3", "intro2",
		"intro1", "introGo"
	];
	var opponent:Character;
	var bf:Character;
	var gf:Character;
	var camFollow:FlxObject;
	var disableCamFollow:Bool = false;
	var defaultCamZoom:Float = 1.05;

	public function new(?song:Song, chars:Array<String>)
	{
		super();
		if (song == null)
			song = Song.loadSong('mods/fnf/songs/Tutorial/Hard');
		this.song = song;
		this.chars = chars;

		persistentUpdate = true;
		destroySubStates = false;
	}

	override public function create()
	{
		if (FlxG.sound.musicPlaying)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music = null;
		}

		Mods.currentMod = song.mod;

		initCameras();
		initSong();
		initUI();
		initPauseSubState();
		initCharacters();
		initStage();
		precache();

		startCountdown();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		timing.update(elapsed);

		ruleset.updateCurrentTrackPosition();
		ruleset.update(elapsed);

		handleInput(elapsed);

		lyricsDisplay.updateLyrics(songInst.time);
		updateCamPosition();

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		timing = FlxDestroyUtil.destroy(timing);
	}

	override function openSubState(subState:FlxSubState)
	{
		if (isPaused)
		{
			FlxG.sound.pause();
			FlxTween.globalManager.forEach(function(twn)
			{
				if (!twn.finished)
					twn.active = false;
			});
			FlxTimer.globalManager.forEach(function(tmr)
			{
				if (!tmr.finished)
					tmr.active = false;
			});
		}

		super.openSubState(subState);
	}

	override function closeSubState()
	{
		super.closeSubState();

		if (isPaused)
		{
			isPaused = false;
			persistentUpdate = true;
			FlxTween.globalManager.forEach(function(twn)
			{
				if (!twn.finished)
					twn.active = true;
			});
			FlxTimer.globalManager.forEach(function(tmr)
			{
				if (!tmr.finished)
					tmr.active = true;
			});
			FlxG.sound.resume();
		}
	}

	public function startSong(timing:MusicTiming)
	{
		hasStarted = true;
	}

	public function exit()
	{
		timing.stopMusic();
		persistentUpdate = false;
		Mods.currentMod = '';
		FlxG.switchState(new SongSelectState());
		CoolUtil.playPvPMusic();
	}

	public function getPlayerCharacter(player:Int)
	{
		return player == 0 ? opponent : bf;
	}

	function initCameras()
	{
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
		ruleset.noteMissed.add(onNoteMissed);
		ruleset.noteReleaseMissed.add(onNoteMissed);
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

	function initPauseSubState()
	{
		pauseSubState = new PauseSubState(this);
	}

	function initCharacters()
	{
		gf = new Character(400, 130, CharacterInfo.loadCharacterFromName(song.gf), true, true);
		gf.scrollFactor.set(0.95, 0.95);
		timing.addDancingSprite(gf);
		add(gf);

		opponent = new Character(100, 100, CharacterInfo.loadCharacterFromName(chars[0]));
		timing.addDancingSprite(opponent);
		add(opponent);

		bf = new Character(770, 100, CharacterInfo.loadCharacterFromName(chars[1]), true);
		timing.addDancingSprite(bf);
		add(bf);
	}

	function initStage()
	{
		camFollow = new FlxObject();
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		updateCamPosition();
		FlxG.camera.snapToTarget();

		FlxG.camera.zoom = defaultCamZoom;
	}

	function updateCamPosition()
	{
		if (disableCamFollow)
			return;

		var camFocus = song.getCameraFocusAt(timing.audioPosition);
		if (camFocus == null)
			return;

		var char = switch (camFocus.char)
		{
			case OPPONENT:
				opponent;
			case BF:
				bf;
			case GF:
				gf;
		}
		var camOffsetX = char.charInfo.cameraOffset[0];
		var camOffsetY = char.charInfo.cameraOffset[1];
		if (char.flipped)
			camOffsetX *= -1;
		camFollow.setPosition(char.x + (char.startWidth / 2) + camOffsetX, char.y + (char.startHeight / 2) + camOffsetY);
	}

	function precache()
	{
		for (image in introSprPaths)
			Paths.getImage('countdown/' + image);
		for (sound in introSndPaths)
			Paths.getSound('countdown/' + sound);
	}

	function handleInput(elapsed:Float)
	{
		if (isPaused)
			return;

		ruleset.handleInput(elapsed);

		for (i in 0...2)
		{
			if (PlayerSettings.checkPlayerAction(i, PAUSE_P))
			{
				isPaused = true;
				persistentUpdate = false;
				pauseSubState.onOpen(i);
				openSubState(pauseSubState);
				break;
			}
		}
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

		var char = getPlayerCharacter(player);
		var timer = char.holdTimers[lane];
		if (timer != null)
		{
			timer.cancel();
			char.holdTimers[lane] = null;
		}
	}

	function onNoteHit(note:Note, judgement:Judgement)
	{
		var player = note.info.player;
		ruleset.playfields[player].onNoteHit(note, judgement);

		var char = getPlayerCharacter(player);
		char.playNoteAnim(note, song.getTimingPointAt(timing.audioPosition).beatLength);
	}

	function onNoteMissed(note:Note)
	{
		var player = note.info.player;
		var char = getPlayerCharacter(player);
		char.playMissAnim(note.info.playerLane);
	}

	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		judgementDisplay.members[player].showJudgement(judgement);
	}

	function startCountdown()
	{
		new FlxTimer().start(song.timingPoints[0].beatLength / 1000, function(tmr)
		{
			var count = tmr.elapsedLoops;
			if (count > 1)
				readySetGo('countdown/' + introSprPaths[count - 2]);
			FlxG.sound.play(Paths.getSound('countdown/' + introSndPaths[count - 1]), 0.6);
		}, 4);
	}

	function readySetGo(path:String):Void
	{
		var spr = new FlxSprite().loadGraphic(Paths.getImage(path));
		spr.scrollFactor.set();
		spr.screenCenter();
		spr.cameras = [camHUD];
		add(spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, song.timingPoints[0].beatLength / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(_)
			{
				spr.destroy();
			}
		});
	}
}
