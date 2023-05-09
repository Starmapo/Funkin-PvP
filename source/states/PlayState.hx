package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import data.char.CharacterInfo;
import data.game.GameplayRuleset;
import data.game.Judgement;
import data.scripts.PlayStateScript;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.animation.FlxAnimationController;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import sprites.game.Character;
import states.pvp.SongSelectState;
import subStates.PauseSubState;
import ui.editors.NotificationManager;
import ui.game.JudgementDisplay;
import ui.game.LyricsDisplay;
import ui.game.Note;
import ui.game.PlayerStatsDisplay;
import ui.game.SongInfoDisplay;
import util.MusicTiming;

using StringTools;

class PlayState extends FNFState
{
	public var song:Song;
	public var chars:Array<String>;
	public var isPaused:Bool = false;
	public var hasStarted:Bool = false;
	public var camHUD:FlxCamera;
	public var timing:MusicTiming;
	public var songInst:FlxSound;
	public var songVocals:FlxSound;
	public var ruleset:GameplayRuleset;
	public var statsDisplay:FlxTypedGroup<PlayerStatsDisplay>;
	public var judgementDisplay:FlxTypedGroup<JudgementDisplay>;
	public var songInfoDisplay:SongInfoDisplay;
	public var lyricsDisplay:LyricsDisplay;
	public var pauseSubState:PauseSubState;
	public var introSprPaths:Array<String> = ["ready", "set", "go"];
	public var introSndPaths:Array<String> = [
		"intro3", "intro2",
		"intro1", "introGo"
	];
	public var opponent:Character;
	public var bf:Character;
	public var gf:Character;
	public var camFollow:FlxObject;
	public var disableCamFollow:Bool = false;
	public var defaultCamZoom:Float = 1.05;
	public var canPause:Bool = false;
	public var scripts:Array<PlayStateScript> = [];
	public var notificationManager:NotificationManager;

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
		FlxAnimationController.globalSpeed = Settings.playbackRate;

		initCameras();
		initSong();
		initUI();
		initPauseSubState();
		initCharacters();
		initStage();
		precache();

		startCountdown();

		super.create();

		executeScripts("onCreatePost");
	}

	override public function update(elapsed:Float)
	{
		executeScripts("onUpdate", [elapsed]);

		timing.update(elapsed);

		ruleset.updateCurrentTrackPosition();
		ruleset.update(elapsed);

		handleInput(elapsed);

		lyricsDisplay.updateLyrics(songInst.time);
		updateCamPosition();

		super.update(elapsed);

		executeScripts("onUpdatePost", [elapsed]);
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
			FlxG.camera.followActive = false;
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
			FlxG.camera.followActive = true;
			FlxG.sound.resume();
		}
	}

	override function finishTransIn()
	{
		super.finishTransIn();
		canPause = true;
	}

	public function startSong(timing:MusicTiming)
	{
		hasStarted = true;
	}

	public function exit()
	{
		timing.stopMusic();
		persistentUpdate = false;
		reset();
		FlxG.switchState(new SongSelectState());
		CoolUtil.playPvPMusic();
	}

	public function reset()
	{
		Mods.currentMod = '';
		FlxAnimationController.globalSpeed = 1;
	}

	public function getPlayerCharacter(player:Int)
	{
		return player == 0 ? opponent : bf;
	}

	public function addScript(key:String, mod:String)
	{
		var path = Paths.getScriptPath(key, mod);
		if (Paths.exists(path))
		{
			var script = new PlayStateScript(this, path, mod);
			scripts.push(script);
			script.execute("onCreate");
			return script;
		}

		return null;
	}

	public function executeScripts(func:String, ?args:Array<Any>)
	{
		for (script in scripts)
		{
			if (script.closed)
			{
				scripts.remove(script);
				continue;
			}

			script.execute(func, args);
		}
	}

	public function triggerEvent(name:String, params:Array<String>)
	{
		switch (name)
		{
			case "Hey!":
				var value1 = params[0] != null ? params[0].toLowerCase().trim() : '';
				var value2 = params[1] != null ? params[1].toLowerCase().trim() : '';

				var time = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				var bfHey = true;
				var gfCheer = true;
				switch (value1)
				{
					case 'bf', 'boyfriend', '0':
						gfCheer = false;
					case 'gf', 'girlfriend', '1':
						bfHey = false;
				}

				if (bfHey)
					bf.playSpecialAnim('hey', time, true);
				if (gfCheer)
					gf.playSpecialAnim('cheer', time, true);

			case "Set GF Speed":
				var value = params[0] != null ? Std.parseInt(params[0].trim()) : 1;
				if (Math.isNaN(value) || value < 1)
					value = 1;
				gf.danceBeats = value;
		}

		executeScripts("onEvent", [name, params]);
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
		songInst.pitch = Settings.playbackRate;

		var vocals = Paths.getSongVocals(song);
		if (vocals != null)
			songVocals = FlxG.sound.load(vocals);
		else
			songVocals = FlxG.sound.list.add(new FlxSound());
		songVocals.pitch = Settings.playbackRate;

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
		ruleset.ghostTap.add(onGhostTap);
		ruleset.noteHit.add(onNoteHit);
		ruleset.noteMissed.add(onNoteMissed);
		ruleset.noteReleaseMissed.add(onNoteReleaseMissed);
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

		notificationManager = new NotificationManager();
		add(notificationManager);
	}

	function initPauseSubState()
	{
		pauseSubState = new PauseSubState(this);
	}

	function initCharacters()
	{
		var gfInfo = CharacterInfo.loadCharacterFromName(song.gf);
		if (gfInfo == null)
			gfInfo = CharacterInfo.loadCharacterFromName('fnf:gf');

		gf = new Character(400, 130, gfInfo, true, true);
		gf.scrollFactor.set(0.95, 0.95);
		timing.addDancingSprite(gf);
		add(gf);

		var opponentName = chars[0] != null ? chars[0] : song.opponent;
		var opponentInfo = CharacterInfo.loadCharacterFromName(opponentName);
		if (opponentInfo == null)
			CharacterInfo.loadCharacterFromName('fnf:dad');

		opponent = new Character(100, 100, opponentInfo);
		timing.addDancingSprite(opponent);
		add(opponent);

		var bfName = chars[1] != null ? chars[1] : song.bf;
		var bfInfo = CharacterInfo.loadCharacterFromName(bfName);
		if (bfInfo == null)
			CharacterInfo.loadCharacterFromName('fnf:bf');

		bf = new Character(770, 100, bfInfo, true);
		timing.addDancingSprite(bf);
		add(bf);
	}

	function initStage()
	{
		camFollow = new FlxObject();
		updateCamPosition();
		add(camFollow);

		addScript('data/stages/' + song.stage, song.mod);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
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

		executeScripts("onLanePressed", [lane, player]);
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

		executeScripts("onLaneReleased", [lane, player]);
	}

	function onGhostTap(lane:Int, player:Int)
	{
		executeScripts("onGhostTap", [lane, player]);
	}

	function onNoteHit(note:Note, judgement:Judgement)
	{
		var player = note.info.player;
		ruleset.playfields[player].onNoteHit(note, judgement);

		var char = getPlayerCharacter(player);
		char.playNoteAnim(note, song.getTimingPointAt(timing.audioPosition).beatLength / Settings.playbackRate);

		executeScripts("onNoteHit", [note, judgement]);
	}

	function onNoteMissed(note:Note)
	{
		var player = note.info.player;
		var char = getPlayerCharacter(player);
		char.playMissAnim(note.info.playerLane);

		executeScripts("onNoteMissed", [note]);
	}

	function onNoteReleaseMissed(note:Note)
	{
		var player = note.info.player;
		var char = getPlayerCharacter(player);
		char.playMissAnim(note.info.playerLane);

		executeScripts("onNoteReleaseMissed", [note]);
	}

	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		judgementDisplay.members[player].showJudgement(judgement);

		executeScripts("onJudgementAdded", [judgement, player]);
	}

	function startCountdown()
	{
		new FlxTimer().start(song.timingPoints[0].beatLength / Settings.playbackRate / 1000, function(tmr)
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
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, song.timingPoints[0].beatLength / Settings.playbackRate / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(_)
			{
				spr.destroy();
			}
		});

		executeScripts("onReadySetGo", [spr]);
	}
}
