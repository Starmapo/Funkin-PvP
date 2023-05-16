package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import data.char.CharacterInfo;
import data.game.GameplayRuleset;
import data.game.Judgement;
import data.scripts.PlayStateScript;
import data.scripts.Script;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.animation.FlxAnimationController;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.io.Path;
import sprites.game.Character;
import subStates.PauseSubState;
import subStates.ResultsScreen;
import sys.FileSystem;
import ui.editors.NotificationManager;
import ui.game.HealthBar;
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
	public var hasEnded:Bool = false;
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
	public var events:Array<PlayStateEvent> = [];
	public var camZooming:Bool = true;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = true;
	public var camBopMult:Float = 1;
	public var healthBars:FlxTypedGroup<HealthBar>;
	public var died:Bool = false;
	public var clearCache:Bool = false;
	public var deathBG:FlxSprite;
	public var deathTimer:FlxTimer;
	public var isComplete(get, never):Bool;

	var instEnded:Bool = false;

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
		if (Settings.clearGameplayCache)
			Paths.trackingAssets = true;

		initCameras();
		initSong();
		initUI();
		initPauseSubState();
		initCharacters();
		initStage();
		initScripts();
		precache();

		checkEvents();
		startCountdown();

		super.create();

		executeScripts("onCreatePost");
	}

	override public function update(elapsed:Float)
	{
		// after the sound is finished playing, its time is reset back to 0 for some reason
		// so i gotta set it manually
		if (instEnded)
			songInst.time = songInst.length;

		executeScripts("onUpdate", [elapsed]);

		super.update(elapsed);

		timing.update(elapsed);

		ruleset.updateCurrentTrackPosition();
		ruleset.update(elapsed);

		handleInput(elapsed);

		if (!hasEnded && isComplete)
			endSong();

		lyricsDisplay.updateLyrics(timing.audioPosition);
		updateCamPosition();
		updateCamZoom(elapsed);

		checkEvents();
		checkDeath();

		updateDeathBG();

		executeScripts("onUpdatePost", [elapsed]);
	}

	override function destroy()
	{
		super.destroy();
		song = null;
		chars = null;
		camHUD = null;
		timing = FlxDestroyUtil.destroy(timing);
		songInst = null;
		songVocals = FlxDestroyUtil.destroy(songVocals);
		ruleset = FlxDestroyUtil.destroy(ruleset);
		statsDisplay = null;
		judgementDisplay = null;
		songInfoDisplay = null;
		lyricsDisplay = null;
		pauseSubState = FlxDestroyUtil.destroy(pauseSubState);
		introSprPaths = null;
		introSndPaths = null;
		opponent = null;
		bf = null;
		gf = null;
		camFollow = null;
		scripts = FlxDestroyUtil.destroyArray(scripts);
		notificationManager = null;
		events = null;
	}

	override function openSubState(subState:FlxSubState)
	{
		setScripts('subState', subState);

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

		setScripts('subState', null);

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

	override function finishTransOut()
	{
		if (clearCache && Settings.clearGameplayCache)
		{
			Paths.clearTrackedAssets();
			Paths.trackingAssets = false;
		}
		super.finishTransOut();
	}

	public function startSong(timing:MusicTiming)
	{
		hasStarted = true;
		executeScripts("onStartSong");
	}

	public function exit(state:FlxState, clearCache:Bool = true)
	{
		timing.stopMusic();
		persistentUpdate = false;
		reset();
		this.clearCache = clearCache;
		FlxG.switchState(state);
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

	public function getNoteCharacter(note:Note)
	{
		return note.gfSing ? gf : getPlayerCharacter(note.info.player);
	}

	public function addScript(key:String, mod:String)
	{
		var path = Paths.getScriptPath(key, mod);
		if (Paths.exists(path))
			return addScriptPath(path, mod);

		return null;
	}

	public function addScriptPath(path:String, mod:String)
	{
		var script = new PlayStateScript(this, path, mod);
		scripts.push(script);
		script.execute("onCreate");
		return script;
	}

	public function addScriptsInFolder(folder:String)
	{
		if (FileSystem.exists(folder) && FileSystem.isDirectory(folder))
		{
			for (file in FileSystem.readDirectory(folder))
			{
				for (ext in Paths.SCRIPT_EXTENSIONS)
				{
					if (file.endsWith(ext))
					{
						addScriptPath(Path.join([folder, file]), song.mod);
						break;
					}
				}
			}
		}
	}

	public function executeScripts(func:String, ?args:Array<Any>, ignoreStops:Bool = true, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic
	{
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];

		var ret:Dynamic = Script.FUNCTION_CONTINUE;
		for (script in scripts)
		{
			if (exclusions.contains(script.path))
				continue;

			var funcRet:Dynamic = script.execute(func, args);
			if (funcRet == Script.FUNCTION_STOP_SCRIPTS && !ignoreStops)
				break;

			if (funcRet != null && funcRet != Script.FUNCTION_CONTINUE && !excludeValues.contains(funcRet))
				ret = funcRet;
		}

		return ret;
	}

	public function setScripts(name:String, value:Dynamic, ?exclusions:Array<String>)
	{
		if (exclusions == null)
			exclusions = [];

		for (script in scripts)
		{
			if (exclusions.contains(script.path))
				continue;

			script.setVariable(name, value);
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
				trace(params, params.length, params[0]);
				var value = params[0] != null ? Std.parseInt(params[0].trim()) : 1;
				if (value == null || Math.isNaN(value) || value < 1)
					value = 1;
				gf.danceBeats = value;
				trace(value);
		}

		executeScripts("onEvent", [name, params]);
	}

	public function endSong()
	{
		if (hasEnded)
			return;

		var ret = executeScripts("onEndSong");
		if (ret != Script.FUNCTION_STOP)
		{
			hasEnded = true;
			camBop = false;
			if (songInst.playing)
				timing.pauseMusic();
			timing.paused = true;
			timing.checkSkippedSteps = false;
			songInst.time = songInst.length;
			songVocals.stop();
			lyricsDisplay.visible = false;
			if (statsDisplay != null)
			{
				for (display in statsDisplay)
					display.visible = false;
			}
			if (songInfoDisplay != null)
				songInfoDisplay.visible = false;
			for (manager in ruleset.inputManagers)
				manager.stopInput();

			var screen = new ResultsScreen(this);
			if (screen.winner > -1)
				focusOnChar(getPlayerCharacter(screen.winner));
			openSubState(screen);
		}
	}

	public function killNotes()
	{
		for (manager in ruleset.noteManagers)
		{
			killLanes(manager.noteQueueLanes);
			killLanes(manager.activeNoteLanes);
			killLanes(manager.heldLongNoteLanes);
			killLanes(manager.deadNoteLanes);
		}
		events.resize(0);
	}

	public function killLanes<T>(lanes:Array<Array<T>>)
	{
		for (lane in lanes)
		{
			while (lane.length > 0)
				lane.shift();
		}
	}

	public function focusOnChar(char:Character)
	{
		var camOffsetX = char.charInfo.cameraOffset[0];
		var camOffsetY = char.charInfo.cameraOffset[1];
		if (char.flipped)
			camOffsetX *= -1;
		camFollow.setPosition(char.x + (char.startWidth / 2) + camOffsetX, char.y + (char.startHeight / 2) + camOffsetY);
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
		songInst.onComplete = function()
		{
			instEnded = true;
		}
		songInst.pitch = Settings.playbackRate;

		var vocals = Paths.getSongVocals(song);
		if (vocals != null)
			songVocals = FlxG.sound.load(vocals);
		else
			songVocals = FlxG.sound.list.add(new FlxSound());
		songVocals.onComplete = function()
		{
			songVocals.volume = 0;
		}
		songVocals.pitch = Settings.playbackRate;

		timing = new MusicTiming(songInst, song.timingPoints, true, song.timingPoints[0].beatLength * 5, [songVocals], startSong);
		timing.onStepHit.add(onStepHit);
		timing.onBeatHit.add(onBeatHit);
		timing.onBarHit.add(onBarHit);
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
		ruleset.noteSpawned.add(onNoteSpawned);

		if (!Settings.hideHUD)
		{
			judgementDisplay = new FlxTypedGroup();
			for (i in 0...2)
				judgementDisplay.add(new JudgementDisplay(i, ruleset.playfields[i].noteSkin));
			judgementDisplay.cameras = [camHUD];
			add(judgementDisplay);

			statsDisplay = new FlxTypedGroup();
			for (i in 0...2)
				statsDisplay.add(new PlayerStatsDisplay(ruleset.scoreProcessors[i]));
			statsDisplay.cameras = [camHUD];
		}

		if (!Settings.hideHUD || Settings.timeDisplay != DISABLED)
		{
			songInfoDisplay = new SongInfoDisplay(song, songInst, timing);
			songInfoDisplay.cameras = [camHUD];
			add(songInfoDisplay);
		}

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

		if (!Settings.hideHUD)
		{
			healthBars = new FlxTypedGroup();
			for (i in 0...2)
				healthBars.add(new HealthBar(ruleset.scoreProcessors[i], getPlayerCharacter(i).charInfo));
			healthBars.cameras = [camHUD];
			add(healthBars);

			add(statsDisplay);
		}
	}

	function initStage()
	{
		deathBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		deathBG.scrollFactor.set();
		deathBG.visible = false;
		updateDeathBG();

		camFollow = new FlxObject();
		updateCamPosition();
		add(camFollow);

		var stageInfo = CoolUtil.getNameInfo(song.stage);
		addScript('data/stages/' + stageInfo.name, stageInfo.mod);

		FlxG.camera.follow(camFollow, LOCKON, 0.04 * Settings.playbackRate);
		FlxG.camera.snapToTarget();

		FlxG.camera.zoom = defaultCamZoom;
	}

	function initScripts()
	{
		addScriptsInFolder(song.directory);

		var characters = [opponent, bf, gf];
		for (char in characters)
			addScript('data/characters/' + char.charInfo.charName, char.charInfo.mod);

		var noteTypeMap = new Map<String, Bool>();
		var eventMap = new Map<String, Bool>();
		for (note in song.notes)
		{
			if (!noteTypeMap.exists(note.type))
				noteTypeMap.set(note.type, true);
		}
		for (event in song.events)
		{
			for (sub in event.events)
			{
				events.push({
					startTime: event.startTime,
					event: sub.event,
					params: sub.params
				});

				if (!eventMap.exists(sub.event))
					eventMap.set(sub.event, true);
			}
		}

		for (note => _ in noteTypeMap)
		{
			var noteInfo = CoolUtil.getNameInfo(note);
			addScript('data/noteTypes/${noteInfo.name}', noteInfo.mod);
		}
		for (event => _ in eventMap)
		{
			var eventInfo = CoolUtil.getNameInfo(event);
			addScript('data/events/${eventInfo.name}', eventInfo.mod);
		}

		addScriptsInFolder('data/globalScripts');

		for (event in events)
			event.startTime -= getEventEarlyTrigger(event);
		events.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime));

		for (manager in ruleset.noteManagers)
		{
			for (lane in manager.activeNoteLanes)
			{
				for (note in lane)
					onNoteSpawned(note);
			}
		}
	}

	function precache()
	{
		for (image in introSprPaths)
			Paths.getImage('countdown/' + image);
		for (sound in introSndPaths)
			Paths.getSound('countdown/' + sound);
	}

	function updateCamPosition()
	{
		if (disableCamFollow || died || hasEnded)
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
		focusOnChar(char);
	}

	function updateCamZoom(elapsed:Float)
	{
		if (camZooming)
		{
			var lerp = (elapsed * 3 * camZoomingDecay * Settings.playbackRate);
			FlxG.camera.zoom = CoolUtil.reverseLerp(defaultCamZoom, FlxG.camera.zoom, lerp);
			camHUD.zoom = CoolUtil.reverseLerp(1, camHUD.zoom, lerp);
		}
	}

	function handleInput(elapsed:Float)
	{
		if (isPaused || hasEnded)
			return;

		ruleset.handleInput(elapsed);

		#if debug
		if (FlxG.keys.justPressed.F1 && hasStarted)
		{
			killNotes();
			endSong();
		}
		#end

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

		var char = getNoteCharacter(note);
		char.playNoteAnim(note, song.getTimingPointAt(timing.audioPosition).beatLength / Settings.playbackRate);

		executeScripts("onNoteHit", [note, judgement]);
	}

	function onNoteMissed(note:Note)
	{
		var char = getNoteCharacter(note);
		char.playMissAnim(note.info.playerLane);

		executeScripts("onNoteMissed", [note]);
	}

	function onNoteReleaseMissed(note:Note)
	{
		var char = getNoteCharacter(note);
		char.playMissAnim(note.info.playerLane);

		executeScripts("onNoteReleaseMissed", [note]);
	}

	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		if (judgementDisplay != null)
			judgementDisplay.members[player].showJudgement(judgement);

		executeScripts("onJudgementAdded", [judgement, player]);
	}

	function onNoteSpawned(note:Note)
	{
		executeScripts("onNoteSpawned", [note]);
	}

	function startCountdown()
	{
		new FlxTimer().start(song.timingPoints[0].beatLength / 1000, function(tmr)
		{
			var count = tmr.elapsedLoops - 1;
			if (count > 0)
				readySetGo('countdown/' + introSprPaths[count - 1]);
			FlxG.sound.play(Paths.getSound('countdown/' + introSndPaths[count]), 0.6);

			executeScripts("onCountdownTick", [count]);
		}, 4);

		executeScripts("onStartCountdown");
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

		executeScripts("onReadySetGo", [spr]);
	}

	function getEventEarlyTrigger(event:PlayStateEvent)
	{
		var value:Dynamic = executeScripts("getEventEarlyTrigger", [event]);
		if (value != 0 && value != Script.FUNCTION_CONTINUE)
			return value;

		return 0;
	}

	function checkEvents()
	{
		while (events.length > 0 && timing.audioPosition >= events[0].startTime)
		{
			var event = events.shift();
			triggerEvent(event.event, event.params);
		}
	}

	function onStepHit(step:Int, decStep:Float)
	{
		if (hasEnded)
			return;

		executeScripts("onStepHit", [step, decStep]);
	}

	function onBeatHit(beat:Int, decBeat:Float)
	{
		if (hasEnded)
			return;

		if (healthBars != null)
		{
			for (bar in healthBars)
				bar.onBeatHit();
		}

		executeScripts("onBeatHit", [beat, decBeat]);
	}

	function onBarHit(bar:Int, decBar:Float)
	{
		if (hasEnded)
			return;

		if (Settings.camZooming && camZooming && camBop && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015 * camBopMult;
			camHUD.zoom += 0.03 * camBopMult;
		}

		executeScripts("onBarHit", [bar, decBar]);
	}

	function updateDeathBG()
	{
		deathBG.setPosition(FlxG.camera.viewMarginX, FlxG.camera.viewMarginY);

		deathBG.setGraphicSize(Math.ceil(FlxG.camera.viewWidth), Math.ceil(FlxG.camera.viewHeight));
		deathBG.updateHitbox();
	}

	function onDeath(player:Int)
	{
		died = true;

		timing.pauseMusic();
		killNotes();

		if (members.indexOf(deathBG) < 0)
		{
			var pos = FlxMath.minInt(FlxMath.minInt(members.indexOf(gf), members.indexOf(opponent)), members.indexOf(bf));
			insert(pos, deathBG);
		}
		deathBG.visible = true;

		var char = getPlayerCharacter(player);
		if (char.allowDanceTimer.active)
			char.allowDanceTimer.cancel();
		for (timer in char.holdTimers)
		{
			if (timer != null && timer.active)
				timer.cancel();
		}
		char.stopAnimCallback();
		char.angularVelocity = 360;
		FlxTween.tween(char.scale, {x: 0, y: 0}, 0.8, {
			onComplete: function(_)
			{
				char.visible = false;
			}
		});

		focusOnChar(char);

		if (deathTimer == null)
			deathTimer = new FlxTimer().start(2, function(_)
			{
				endSong();
			});

		FlxG.camera.flash(FlxColor.WHITE, 0.5);
		FlxG.sound.play(Paths.getSound('death/default'));

		executeScripts("onDeath", [player]);
	}

	function checkDeath()
	{
		if (died || hasEnded)
			return;

		for (i in 0...2)
		{
			var score = ruleset.scoreProcessors[i];
			if (score.failed)
				onDeath(i);
		}
	}

	function get_isComplete()
	{
		for (manager in ruleset.noteManagers)
		{
			for (lane in manager.activeNoteLanes)
			{
				if (lane.length > 0)
					return false;
			}
			for (lane in manager.heldLongNoteLanes)
			{
				if (lane.length > 0)
					return false;
			}
		}

		return timing.audioPosition > songInst.length;
	}
}

typedef PlayStateEvent =
{
	var startTime:Float;
	var event:String;
	var params:Array<String>;
}
