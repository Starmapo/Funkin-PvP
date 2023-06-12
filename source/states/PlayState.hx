package states;

import data.Mods;
import data.PlayerSettings;
import data.Settings;
import data.StageFile;
import data.char.CharacterInfo;
import data.game.GameplayRuleset;
import data.game.Judgement;
import data.scripts.PlayStateScript;
import data.scripts.Script;
import data.skin.JudgementSkin;
import data.song.Song;
import flixel.FlxBasic;
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
import sprites.AnimatedSprite;
import sprites.game.Character;
import states.pvp.SongSelectState;
import subStates.PauseSubState;
import subStates.ResultsScreen;
import sys.FileSystem;
import ui.editors.NotificationManager;
import ui.game.HealthBar;
import ui.game.JudgementCounter;
import ui.game.JudgementDisplay;
import ui.game.LyricsDisplay;
import ui.game.MSDisplay;
import ui.game.NPSDisplay;
import ui.game.Note;
import ui.game.PlayerStatsDisplay;
import ui.game.SongInfoDisplay;
import util.DiscordClient;
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
	public var backgroundCover:FlxSprite;
	public var detailsText:String;
	public var pausedDetailsText:String;
	public var judgementCounters:FlxTypedGroup<JudgementCounter>;
	public var npsDisplay:FlxTypedGroup<NPSDisplay>;
	public var msDisplay:FlxTypedGroup<MSDisplay>;
	public var staticBG:AnimatedSprite;
	public var stageFile:StageFile;

	var instEnded:Bool = false;

	public function new(?map:Song, chars:Array<String>)
	{
		super();
		if (map == null)
			map = Song.loadSong('Tutorial/Hard');
		song = map;
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
		{
			songInst.time = songInst.length;
			if (timing.time < songInst.time)
				timing.setTime(songInst.time);
		}

		executeScripts("onUpdate", [elapsed]);

		super.update(elapsed);

		timing.update(elapsed);
		ruleset.update(elapsed);
		handleInput(elapsed);

		if (!hasEnded && isComplete)
			endSong();

		lyricsDisplay.updateLyrics(timing.audioPosition);
		updateCamPosition();
		updateCamZoom(elapsed);

		checkEvents();
		checkDeath();

		updateBG();

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
		healthBars = null;
		deathBG = null;
		deathTimer = null;
		backgroundCover = null;
		judgementCounters = null;
		npsDisplay = null;
		msDisplay = null;
		staticBG = null;
		stageFile = null;
	}

	override function openSubState(subState:FlxSubState)
	{
		setScripts('subState', subState);

		if (isPaused)
		{
			FlxG.sound.pause();
			FlxTween.globalManager.forEach(function(twn)
			{
				if (!twn.finished && !twn.persist)
					twn.active = false;
			});
			FlxTimer.globalManager.forEach(function(tmr)
			{
				if (!tmr.finished && !tmr.persist)
					tmr.active = false;
			});
			FlxG.camera.followActive = false;

			DiscordClient.changePresence(pausedDetailsText, 'In a match');
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
				if (!twn.finished && !twn.persist)
					twn.active = true;
			});
			FlxTimer.globalManager.forEach(function(tmr)
			{
				if (!tmr.finished && !tmr.persist)
					tmr.active = true;
			});
			FlxG.camera.followActive = true;
			FlxG.sound.resume();

			if (hasStarted)
				DiscordClient.changePresence(detailsText, 'In a match', null, true, getTimeRemaining());
			else
				DiscordClient.changePresence(detailsText, 'In a match');
		}
	}

	override function onFocus()
	{
		if (FlxG.autoPause && !hasEnded)
		{
			if (hasStarted)
				DiscordClient.changePresence(detailsText, 'In a match', null, true, getTimeRemaining());
			else
				DiscordClient.changePresence(detailsText, 'In a match');
		}
	}

	override function onFocusLost()
	{
		if (FlxG.autoPause && !hasEnded)
			DiscordClient.changePresence(pausedDetailsText, 'In a match');
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
		DiscordClient.changePresence(detailsText, 'In a match', null, true, getSongLength());
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
		if (note.character != null)
			return note.character;

		return note.gfSing ? gf : getPlayerCharacter(note.info.player);
	}

	public function addScript(key:String, mod:String, execute:Bool = true)
	{
		var path = Paths.getScriptPath(key, mod);
		if (Paths.exists(path))
			return addScriptPath(path, mod, execute);

		return null;
	}

	public function addScriptPath(path:String, mod:String, execute:Bool = true)
	{
		var script = new PlayStateScript(this, path, mod);
		scripts.push(script);
		if (execute)
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
				time /= Settings.playbackRate;

				var bfHey = true;
				var gfHey = true;
				switch (value1)
				{
					case 'bf', 'boyfriend', '0':
						gfHey = false;
					case 'gf', 'girlfriend', '1':
						bfHey = false;
				}

				if (bfHey)
					bf.playSpecialAnim('hey', time, true);
				if (gfHey)
					gf.playSpecialAnim('hey', time, true);

			case "Set GF Speed":
				var value = params[0] != null ? Std.parseInt(params[0].trim()) : null;
				if (value == null || value < 1)
					value = 1;
				gf.danceBeats = value;

			case "Add Camera Zoom":
				if (Settings.camZooming && camZooming && camBop && FlxG.camera.zoom < 1.35)
				{
					var camZoom = params[0] != null ? Std.parseFloat(params[0].trim()) : Math.NaN;
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					var hudZoom = params[1] != null ? Std.parseFloat(params[1].trim()) : Math.NaN;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom * camBopMult;
					camHUD.zoom += hudZoom * camBopMult;
				}

			case 'Play Animation':
				var char = opponent;
				if (params[1] != null)
				{
					switch (params[1].trim())
					{
						case 'bf', 'boyfriend', '1':
							char = bf;
						case 'gf', 'girlfriend', '2':
							char = gf;
					}
				}
				var time = params[2] != null ? Std.parseFloat(params[2].trim()) : Math.NaN;
				if (Math.isNaN(time) || time < 0)
					time = 0;
				char.playSpecialAnim(params[0], time, true);

			case 'Camera Follow Pos':
				if (params[0] != null && params[0].length > 0)
				{
					var x = params[0] != null ? Std.parseFloat(params[0].trim()) : Math.NaN;
					if (Math.isNaN(x))
						x = 0;
					var y = params[1] != null ? Std.parseFloat(params[1].trim()) : Math.NaN;
					if (Math.isNaN(y))
						y = 0;
					camFollow.setPosition(x, y);
					disableCamFollow = true;
				}
				else
					disableCamFollow = false;

			case 'Screen Shake':
				var valuesArray:Array<Array<String>> = [[params[0], params[1]], [params[2], params[3]]];
				var targetsArray:Array<FlxCamera> = [FlxG.camera, camHUD];
				for (i in 0...targetsArray.length)
				{
					var values:Array<String> = valuesArray[i];
					if (values == null)
						continue;

					var duration:Float = values[0] != null ? Std.parseFloat(values[0].trim()) : Math.NaN;
					if (Math.isNaN(duration))
						duration = 0;
					var intensity:Float = values[1] != null ? Std.parseFloat(values[1].trim()) : Math.NaN;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
						targetsArray[i].shake(intensity, duration);
				}

			case 'Set Property':
				if (params[0] != null)
				{
					var killMe:Array<String> = params[0].split('.');
					if (killMe.length > 1)
						CoolUtil.setVarInArray(CoolUtil.getPropertyLoopThingWhatever(killMe, true), killMe[killMe.length - 1], params[1]);
					else
						CoolUtil.setVarInArray(this, params[0], params[1]);
				}
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
			ruleset.stopInput();

			if (Settings.resultsScreen)
			{
				var screen = new ResultsScreen(this);
				if (screen.winner > -1)
					focusOnChar(getPlayerCharacter(screen.winner));
				openSubState(screen);

				var winText = switch (screen.winner)
				{
					case -1: 'Tie';
					default: 'Player ${screen.winner + 1} wins';
				}

				DiscordClient.changePresence(winText + ' - ' + detailsText, 'Results Screen');
			}
			else
			{
				exit(new SongSelectState());
				CoolUtil.playPvPMusic();
			}
		}
	}

	public function killNotes()
	{
		ruleset.killNotes();
		events.resize(0);
	}

	public function focusOnChar(char:Character)
	{
		var camOffsetX = char.charInfo.cameraOffset[0];
		var camOffsetY = char.charInfo.cameraOffset[1];
		if (char.charFlipX)
			camOffsetX *= -1;
		if (Settings.cameraNoteMovements)
		{
			camOffsetX += char.camOffset.x;
			camOffsetY += char.camOffset.y;
		}

		camFollow.setPosition(char.x + (char.startWidth / 2) + camOffsetX, char.y + (char.startHeight / 2) + camOffsetY);
	}

	public function getSongLength()
	{
		return (songInst.length / songInst.pitch) - Settings.globalOffset;
	}

	public function getTimeRemaining()
	{
		return getSongLength() - (timing.time / songInst.pitch) + Settings.globalOffset;
	}

	public function playNoteAnim(char:Character, note:Note)
	{
		char.playNoteAnim(note, getBeatLength());
	}

	public function getBeatLength()
	{
		return song.getTimingPointAt(timing.audioPosition).beatLength / Settings.playbackRate;
	}

	function initCameras()
	{
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
	}

	function initSong()
	{
		songInst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup, false, false, null, function()
		{
			instEnded = true;
			songInst.stop();
			songInst.time = songInst.length;
		});
		songInst.pitch = Settings.playbackRate;
		songInst.resetPositionOnFinish = false;

		var vocals = Paths.getSongVocals(song);
		if (vocals != null)
			songVocals = FlxG.sound.load(vocals, 1, false, FlxG.sound.defaultMusicGroup, false, false, null, function()
			{
				songVocals.volume = 0;
			});
		else
			songVocals = FlxG.sound.list.add(new FlxSound());
		songVocals.pitch = Settings.playbackRate;
		songVocals.resetPositionOnFinish = false;

		timing = new MusicTiming(songInst, song.timingPoints, false, song.timingPoints[0].beatLength * 5, [songVocals], startSong);
		timing.onStepHit.add(onStepHit);
		timing.onBeatHit.add(onBeatHit);
		timing.onBarHit.add(onBarHit);

		detailsText = song.title + ' [${song.difficultyName}]';
		pausedDetailsText = 'Paused - $detailsText';
		DiscordClient.changePresence(detailsText, 'In a match');
	}

	function initUI()
	{
		if (Settings.backgroundBrightness < 1)
		{
			backgroundCover = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGBFloat(0, 0, 0, 1 - Settings.backgroundBrightness));
			backgroundCover.setGraphicSize(FlxG.width, FlxG.height);
			backgroundCover.updateHitbox();
			backgroundCover.cameras = [camHUD];
			add(backgroundCover);
		}

		ruleset = new GameplayRuleset(song, timing);
		for (playfield in ruleset.playfields)
		{
			playfield.cameras = [camHUD];
			add(playfield);
		}

		ruleset.lanePressed.add(onLanePressed);
		ruleset.laneReleased.add(onLaneReleased);
		ruleset.ghostTap.add(onGhostTap);
		ruleset.noteHit.add(onNoteHit);
		ruleset.noteMissed.add(onNoteMissed);
		ruleset.noteReleased.add(onNoteReleased);
		ruleset.noteReleaseMissed.add(onNoteReleaseMissed);
		ruleset.judgementAdded.add(onJudgementAdded);
		ruleset.noteSpawned.add(onNoteSpawned);

		if (!Settings.hideHUD)
		{
			judgementDisplay = new FlxTypedGroup();
			for (i in 0...2)
				judgementDisplay.add(new JudgementDisplay(i, JudgementSkin.loadSkinFromName(PlayerSettings.players[i].config.judgementSkin)));
			judgementDisplay.cameras = [camHUD];
			add(judgementDisplay);

			statsDisplay = new FlxTypedGroup();
			for (i in 0...2)
				statsDisplay.add(new PlayerStatsDisplay(ruleset.playfields[i].scoreProcessor));
			statsDisplay.cameras = [camHUD];
		}

		msDisplay = new FlxTypedGroup();
		for (i in 0...2)
		{
			var display = new MSDisplay(i);
			display.exists = Settings.playerConfigs[i].msDisplay;
			msDisplay.add(display);
		}
		msDisplay.cameras = [camHUD];
		add(msDisplay);

		judgementCounters = new FlxTypedGroup();
		for (i in 0...2)
		{
			var counter = new JudgementCounter(ruleset.playfields[i].scoreProcessor);
			counter.exists = Settings.playerConfigs[i].judgementCounter;
			judgementCounters.add(counter);
		}
		judgementCounters.cameras = [camHUD];
		add(judgementCounters);

		npsDisplay = new FlxTypedGroup();
		for (i in 0...2)
		{
			var display = new NPSDisplay(i);
			display.exists = Settings.playerConfigs[i].npsDisplay;
			npsDisplay.add(display);
		}
		npsDisplay.cameras = [camHUD];

		if (!Settings.hideHUD || Settings.timeDisplay != DISABLED)
		{
			songInfoDisplay = new SongInfoDisplay(song, songInst, timing);
			songInfoDisplay.cameras = [camHUD];
		}

		lyricsDisplay = new LyricsDisplay(song, Song.getSongLyrics(song));
		lyricsDisplay.cameras = [camHUD];

		notificationManager = new NotificationManager();
		notificationManager.cameras = [camHUD];
	}

	function initPauseSubState()
	{
		pauseSubState = new PauseSubState(this);
	}

	function initCharacters()
	{
		staticBG = new AnimatedSprite();
		staticBG.frames = Paths.getSpritesheet('stages/static');
		staticBG.animation.addByPrefix('static', 'menuStatic_');
		staticBG.setGraphicSize(FlxG.width, FlxG.height);
		staticBG.updateHitbox();
		staticBG.playAnim('static');
		if (!Settings.distractions)
			staticBG.animation.pause();
		staticBG.scrollFactor.set();
		add(staticBG);

		var gfInfo = CharacterInfo.loadCharacterFromName(song.gf);
		if (gfInfo == null)
			gfInfo = CharacterInfo.loadCharacterFromName('fnf:gf');

		gf = new Character(400, 130, gfInfo, false, true);
		gf.scrollFactor.set(0.95, 0.95);
		timing.addDancingSprite(gf);

		var opponentName = chars[0] != null ? chars[0] : song.opponent;
		var opponentInfo = CharacterInfo.loadCharacterFromName(opponentName);
		if (opponentInfo == null)
			CharacterInfo.loadCharacterFromName('fnf:dad');

		opponent = new Character(100, 100, opponentInfo);
		timing.addDancingSprite(opponent);

		var bfName = chars[1] != null ? chars[1] : song.bf;
		var bfInfo = CharacterInfo.loadCharacterFromName(bfName);
		if (bfInfo == null)
			CharacterInfo.loadCharacterFromName('fnf:bf');

		bf = new Character(770, 100, bfInfo, true);
		timing.addDancingSprite(bf);

		if (!Settings.hideHUD)
		{
			if (Settings.healthBarAlpha > 0)
			{
				healthBars = new FlxTypedGroup();
				for (i in 0...2)
					healthBars.add(new HealthBar(ruleset.playfields[i].scoreProcessor, getPlayerCharacter(i).charInfo));
				healthBars.cameras = [camHUD];
				add(healthBars);
			}

			add(statsDisplay);
		}

		add(npsDisplay);
		if (songInfoDisplay != null)
			add(songInfoDisplay);
		add(lyricsDisplay);
		add(notificationManager);
	}

	function initStage()
	{
		deathBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		deathBG.scrollFactor.set();
		deathBG.visible = false;
		updateBG();

		camFollow = new FlxObject();
		updateCamPosition();
		add(camFollow);

		var stage = Settings.forceDefaultStage ? 'fnf:stage' : song.stage;
		stageFile = new StageFile(this, stage);

		var stageInfo = CoolUtil.getNameInfo(stage);
		var stageScript = addScript('data/stages/' + stageInfo.name, stageInfo.mod, false);
		if (stageScript != null)
		{
			for (name => spr in stageFile.sprites)
				stageScript.setVariable(name, spr);
			stageScript.execute("onCreate");
		}

		FlxG.camera.follow(camFollow, LOCKON, 0.04 * Settings.playbackRate);
		FlxG.camera.snapToTarget();

		FlxG.camera.zoom = defaultCamZoom;
	}

	function initScripts()
	{
		addScriptsInFolder(song.directory);

		var characters = [opponent, bf, gf];
		for (char in characters)
			addScript('data/characters/' + char.charInfo.name, char.charInfo.mod);

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

		for (playfield in ruleset.playfields)
		{
			for (lane in playfield.noteManager.activeNoteLanes)
			{
				for (note in lane)
					onNoteSpawned(note);
			}
		}
	}

	function precache()
	{
		for (image in introSprPaths)
			precacheImage('countdown/' + image);
		for (sound in introSndPaths)
			Paths.getSound('countdown/' + sound);

		for (display in judgementDisplay)
		{
			for (graphic in display.graphics)
				precacheGraphic(graphic);
		}

		if (Settings.missSounds)
		{
			for (i in 1...4)
				Paths.getSound('miss/missnote$i');
		}
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
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 1 - lerp);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 1 - lerp);
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
				pauseSubState.setPlayer(i);
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
		if (!Settings.ghostTapping)
		{
			var char = getPlayerCharacter(player);
			char.playMissAnim(lane);

			if (Settings.missSounds)
				playMissSound();
		}

		executeScripts("onGhostTap", [lane, player]);
	}

	function onNoteHit(note:Note, judgement:Judgement, ms:Float)
	{
		var player = note.info.player;
		ruleset.playfields[player].onNoteHit(note, judgement);

		if (!note.noAnim)
		{
			var char = getNoteCharacter(note);
			if (note.heyNote)
				char.playSpecialAnim('hey', 0.6, true);
			else if (note.info.type == 'Play Animation')
			{
				var anim = note.info.params[0] != null ? note.info.params[0].trim() : '';
				if (char.animation.exists(anim))
				{
					var force = true;
					if (note.info.params[1] != null)
					{
						var param = note.info.params[1].trim();
						force = param != 'false' && param != '0';
					}
					char.playAnim(anim, force);
				}
				else
					playNoteAnim(char, note);
			}
			else if (note.info.type == 'Special Animation')
			{
				var anim = note.info.params[0] != null ? note.info.params[0].trim() : '';
				if (char.animation.exists(anim))
				{
					var time = note.info.params[1] != null ? Std.parseFloat(note.info.params[1].trim()) : Math.NaN;
					if (Math.isNaN(time) || time < 0)
						time = 0;
					var force = true;
					if (note.info.params[2] != null)
					{
						var param = note.info.params[2].trim();
						force = param != 'false' && param != '0';
					}
					char.playSpecialAnim(anim, time, force);
				}
				else
					playNoteAnim(char, note);
			}
			else
				playNoteAnim(char, note);
		}

		npsDisplay.members[player].addTime(Sys.time());

		msDisplay.members[player].showMS(ms, judgement);

		executeScripts("onNoteHit", [note, judgement, ms]);
	}

	function onNoteMissed(note:Note)
	{
		if (!note.noMissAnim)
		{
			var char = getNoteCharacter(note);
			char.playMissAnim(note.info.playerLane);
		}

		if (Settings.missSounds)
			playMissSound();

		executeScripts("onNoteMissed", [note]);
	}

	function onNoteReleased(note:Note, judgement:Judgement, ms:Float)
	{
		var player = note.info.player;
		msDisplay.members[player].showMS(ms, judgement);

		executeScripts("onNoteReleased", [note, judgement, ms]);
	}

	function onNoteReleaseMissed(note:Note)
	{
		if (!note.noMissAnim)
		{
			var char = getNoteCharacter(note);
			char.playMissAnim(note.info.playerLane);
		}

		if (Settings.missSounds)
			playMissSound();

		executeScripts("onNoteReleaseMissed", [note]);
	}

	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		if (judgementDisplay != null)
			judgementDisplay.members[player].showJudgement(judgement);

		judgementCounters.members[player].updateText();

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

	function updateBG()
	{
		var camWidth = FlxG.camera.viewWidth;
		var camHeight = FlxG.camera.viewHeight;
		for (bg in [staticBG, deathBG])
		{
			bg.setPosition(FlxG.camera.viewMarginX, FlxG.camera.viewMarginY);
			if (bg.width != camWidth || bg.height != camHeight)
			{
				bg.setGraphicSize(camWidth, camHeight);
				bg.updateHitbox();
			}
		}
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
		if (died || !hasStarted || hasEnded)
			return;

		for (i in 0...2)
		{
			var score = ruleset.playfields[i].scoreProcessor;
			var reset = (!PlayerSettings.players[i].config.noReset && PlayerSettings.checkPlayerAction(i, RESET_P));
			if (score.failed || reset)
				onDeath(i);
		}
	}

	function playMissSound()
	{
		FlxG.sound.play(Paths.getSound('miss/missnote' + FlxG.random.int(1, 3)), FlxG.random.float(0.1, 0.2));
	}

	function get_isComplete()
	{
		for (playfield in ruleset.playfields)
		{
			var manager = playfield.noteManager;
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
