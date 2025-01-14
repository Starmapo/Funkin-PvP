package states;

import backend.Music;
import backend.MusicTiming;
import backend.game.GameplayGlobals;
import backend.game.GameplayRuleset;
import backend.game.Judgement;
import backend.scripts.PlayStateScript;
import backend.scripts.Script;
import backend.structures.StageFile;
import backend.structures.char.CharacterInfo;
import backend.structures.skin.JudgementSkin;
import backend.structures.song.Song;
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
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.io.Path;
import objects.CameraBackground;
import objects.game.Character;
import objects.game.HealthBar;
import objects.game.JudgementCounter;
import objects.game.JudgementDisplay;
import objects.game.LyricsDisplay;
import objects.game.MSDisplay;
import objects.game.NPSDisplay;
import objects.game.Note;
import objects.game.PlayerStatsDisplay;
import objects.game.SongInfoDisplay;
import states.editors.SongEditorState;
import states.pvp.SongSelectState;
import subStates.PauseSubState;
import subStates.ResultsScreen;

using StringTools;

class PlayState extends FNFState
{
	public static var chars:Array<String> = [];
	
	public var song:Song;
	public var isPaused:Bool = false;
	public var hasStarted:Bool = false;
	public var hasEnded:Bool = false;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var timing:MusicTiming;
	public var inst:FlxSound;
	public var vocals:FlxSound;
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
	public var scripts:Map<String, Script> = [];
	public var events:Array<PlayStateEvent> = [];
	public var camZooming:Bool = false;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = false;
	public var camBopMult:Float = 1;
	public var healthBars:FlxTypedGroup<HealthBar>;
	public var died:Bool = false;
	public var deathBG:CameraBackground;
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
	public var camBopRate:Null<Int> = null;
	public var iconBop:Bool = true;
	public var defaultCamZoomTween:FlxTween;
	public var afterRulesetUpdate:FlxTypedSignal<Float->Void> = new FlxTypedSignal();
	public var minScrollX:Null<Float>;
	public var maxScrollX:Null<Float>;
	public var minScrollY:Null<Float>;
	public var maxScrollY:Null<Float>;
	public var opponentCamX:Null<Float>;
	public var opponentCamY:Null<Float>;
	public var bfCamX:Null<Float>;
	public var bfCamY:Null<Float>;
	public var gfCamX:Null<Float>;
	public var gfCamY:Null<Float>;
	
	var instEnded:Bool = false;
	var debugMode:Bool = false;
	var hitNote:Bool = false;
	
	public function new(?map:Song, ?chars:Array<String>)
	{
		super();
		if (map == null)
			map = Song.loadSong('Tutorial/Hard');
		song = map;
		if (chars != null)
			PlayState.chars = chars;
			
		persistentUpdate = true;
		destroySubStates = false;
		
		GameplayGlobals.playbackRate = Settings.playbackRate;
	}
	
	override public function create()
	{
		Music.stopMusic();
		
		// no thinking outside the box!
		if (!SongSelectState.canSelectChars)
			chars = [];
			
		Mods.currentMod = song.mod;
		FlxAnimationController.globalSpeed = GameplayGlobals.playbackRate;
		
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
		
		callOnScripts("onCreatePost");
	}
	
	override public function update(elapsed:Float)
	{
		// after the sound is finished playing, its time is reset back to 0 for some reason
		// so i gotta set it manually
		if (instEnded)
		{
			inst.time = inst.length;
			if (timing.time < inst.time)
				timing.setTime(inst.time);
		}
		
		callOnScripts("onUpdate", [elapsed]);
		
		super.update(elapsed);
		
		timing.update(elapsed);
		ruleset.update(elapsed);
		afterRulesetUpdate.dispatch(elapsed);
		
		handleInput(elapsed);
		
		if (!hasEnded && isComplete)
			endSong();
			
		lyricsDisplay.updateLyrics(timing.audioPosition);
		updateCamPosition();
		updateCamZoom(elapsed);
		
		checkEvents();
		checkDeath();
		
		updateBG();
		
		callOnScripts("onUpdatePost", [elapsed]);
		
		if (FlxG.mouse.visible)
			FlxG.mouse.visible = false;
	}
	
	override function destroy()
	{
		super.destroy();
		song = null;
		camHUD = null;
		camOther = null;
		timing = FlxDestroyUtil.destroy(timing);
		inst = null;
		vocals = null;
		ruleset = FlxDestroyUtil.destroy(ruleset);
		statsDisplay = FlxDestroyUtil.destroy(statsDisplay);
		judgementDisplay = FlxDestroyUtil.destroy(judgementDisplay);
		songInfoDisplay = FlxDestroyUtil.destroy(songInfoDisplay);
		lyricsDisplay = FlxDestroyUtil.destroy(lyricsDisplay);
		pauseSubState = FlxDestroyUtil.destroy(pauseSubState);
		introSprPaths = null;
		introSndPaths = null;
		opponent = FlxDestroyUtil.destroy(opponent);
		bf = FlxDestroyUtil.destroy(bf);
		gf = FlxDestroyUtil.destroy(gf);
		camFollow = FlxDestroyUtil.destroy(camFollow);
		if (scripts != null)
		{
			for (_ => s in scripts)
				FlxDestroyUtil.destroy(s);
			scripts = null;
		}
		events = null;
		healthBars = FlxDestroyUtil.destroy(healthBars);
		deathBG = FlxDestroyUtil.destroy(deathBG);
		deathTimer = null;
		backgroundCover = FlxDestroyUtil.destroy(backgroundCover);
		judgementCounters = FlxDestroyUtil.destroy(judgementCounters);
		npsDisplay = FlxDestroyUtil.destroy(npsDisplay);
		msDisplay = FlxDestroyUtil.destroy(msDisplay);
		staticBG = FlxDestroyUtil.destroy(staticBG);
		stageFile = FlxDestroyUtil.destroy(stageFile);
	}
	
	override function openSubState(subState:FlxSubState)
	{
		super.openSubState(subState);
		
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
			
			FlxG.camera.active = false;
			
			DiscordClient.changePresence(pausedDetailsText, 'In a match');
		}
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
			
			FlxG.camera.active = true;
			
			if (hasStarted)
				DiscordClient.changePresence(detailsText, 'In a match', null, true, getTimeRemaining());
			else
				DiscordClient.changePresence(detailsText, 'In a match');
				
			FlxG.sound.resume();
			
			callOnScripts("onResume");
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
	
	public function startSong(timing:MusicTiming)
	{
		hasStarted = true;
		DiscordClient.changePresence(detailsText, 'In a match', null, true, getSongLength());
		callOnScripts("onStartSong");
	}
	
	public function exit(state:FlxState, clearCache:Bool = false)
	{
		timing.stopMusic();
		persistentUpdate = false;
		reset();
		if (clearCache)
			Paths.clearCache = true;
		destroySubStates = true;
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
		if (path != null && Paths.exists(path))
			return addScriptFromPath(path, mod, execute);
			
		return null;
	}
	
	public function addScriptFromPath(path:String, mod:String, execute:Bool = true)
	{
		// Don't add a script if the path is null, dummy.
		if (path == null)
			return null;
		// Don't add a script more than once!
		if (scripts.exists(path))
			return scripts.get(path);
			
		var script = Script.getScript(path, mod);
		PlayStateScript.implement(script, this);
		scripts.set(path, script);
		
		if (execute)
			script.call("onCreate");
			
		return script;
	}
	
	public function addScriptsInFolder(folder:String)
	{
		if (Paths.exists(folder) && Paths.isDirectory(folder))
		{
			for (file in Paths.readDirectory(folder))
			{
				var full = Path.join([folder, file]);
				if (Paths.isDirectory(full))
					addScriptsInFolder(full);
				else
				{
					for (ext in Paths.SCRIPT_EXTENSIONS)
					{
						if (file.endsWith(ext))
						{
							addScriptFromPath(full, song.mod);
							break;
						}
					}
				}
			}
		}
	}
	
	public function callOnScripts(func:String, ?args:Array<Any>, ignoreStops:Bool = true, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic
	{
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];
			
		var ret:Dynamic = Script.FUNCTION_CONTINUE;
		for (path => script in scripts)
		{
			if (exclusions.contains(path))
				continue;
				
			var funcRet:Dynamic = script.call(func, args);
			if (!ignoreStops)
			{
				if (funcRet == Script.FUNCTION_BREAK)
					break;
				else if (funcRet == Script.FUNCTION_STOP_BREAK)
				{
					ret = Script.FUNCTION_STOP;
					break;
				}
			}
			
			if (funcRet != null && funcRet != Script.FUNCTION_CONTINUE && !excludeValues.contains(funcRet))
				ret = funcRet;
		}
		
		return ret;
	}
	
	public function setScripts(name:String, value:Dynamic, ?exclusions:Array<String>)
	{
		if (exclusions == null)
			exclusions = [];
			
		for (path => script in scripts)
		{
			if (exclusions.contains(path))
				continue;
				
			script.set(name, value);
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
				time /= GameplayGlobals.playbackRate;
				
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
				time /= GameplayGlobals.playbackRate;
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
					setCamFollow(x, y);
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
					duration /= GameplayGlobals.playbackRate;
					var intensity:Float = values[1] != null ? Std.parseFloat(values[1].trim()) : Math.NaN;
					if (Math.isNaN(intensity))
						intensity = 0;
						
					if (duration > 0 && intensity != 0)
						targetsArray[i].shake(intensity, duration);
				}
				
			case 'Set Property':
				if (params[0] != null && params[0].length > 0)
				{
					var killMe:Array<String> = params[0].split('.');
					if (killMe.length > 1)
						CoolUtil.setVarInArray(CoolUtil.getPropertyLoopThingWhatever(killMe, true), killMe[killMe.length - 1], params[1]);
					else
						CoolUtil.setVarInArray(this, params[0], params[1]);
				}
				
			case 'Set Camera Bop Rate':
				if (params[0] != null && params[0].length > 0)
					camBopRate = Std.parseInt(params[0]);
				else
					camBopRate = null;
					
			case "Set Default Camera Zoom":
				if (params[0] != null && params[0].length > 0)
				{
					var zoom = Std.parseFloat(params[0].trim());
					if (!Math.isNaN(zoom))
						defaultCamZoom = zoom;
				}
				
			case "Tween Default Camera Zoom":
				if (params[0] != null && params[0].length > 0)
				{
					var zoom = Std.parseFloat(params[0].trim());
					if (!Math.isNaN(zoom))
					{
						if (defaultCamZoomTween != null)
							defaultCamZoomTween.cancel();
							
						var duration = params[1] != null ? Std.parseFloat(params[1].trim()) : Math.NaN;
						if (Math.isNaN(duration))
							duration = 1;
						duration /= GameplayGlobals.playbackRate;
						var ease:Float->Float = params[2] != null ? Reflect.field(FlxEase, params[2].trim()) : null;
						defaultCamZoomTween = FlxTween.tween(this, {defaultCamZoom: zoom}, duration, {ease: ease});
					}
				}
		}
		
		callOnScripts("onEvent", [name, params]);
	}
	
	public function endSong()
	{
		if (hasEnded)
			return;
			
		var ret = callOnScripts("onEndSong");
		if (ret != Script.FUNCTION_STOP)
		{
			hasEnded = true;
			camBop = false;
			if (inst.playing)
				timing.pauseMusic();
			timing.paused = true;
			inst.time = inst.length;
			vocals.stop();
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
				var chars = [opponent, bf];
				for (char in chars)
				{
					if (char.animation.exists('outro'))
					{
						char.playSpecialAnim('outro');
						char.danceDisabled = true;
					}
				}
				var screen = new ResultsScreen(this);
				if (screen.winner > -1 && !disableCamFollow)
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
				exit(new SongSelectState(), true);
		}
	}
	
	public function killNotes()
	{
		ruleset.killNotes();
		events.resize(0);
	}
	
	public function focusOnChar(char:Character)
	{
		if (char == null)
			return;
			
		var camX:Null<Float> = if (char == opponent) opponentCamX else if (char == bf) bfCamX else if (char == gf) gfCamX else null;
		var camY:Null<Float> = if (char == opponent) opponentCamY else if (char == bf) bfCamY else if (char == gf) gfCamY else null;
		if (camX == null)
		{
			var camOffsetX = char.info != null ? char.info.cameraOffset[0] : 0;
			if (char.charFlipX)
				camOffsetX *= -1;
			camX = char.x + (char.startWidth / 2) + camOffsetX;
		}
		if (camY == null)
			camY = char.y + (char.startHeight / 2) + (char.info != null ? char.info.cameraOffset[1] : 0);
			
		if (Settings.cameraNoteMovements)
		{
			camX += char.camOffset.x;
			camY += char.camOffset.y;
		}
		
		setCamFollow(camX, camY);
		
		callOnScripts("onCharFocus", [char]);
	}
	
	public function setCamFollow(x:Float = 0, y:Float = 0, ignoreBounds:Bool = false)
	{
		if (ignoreBounds)
		{
			camFollow.setPosition(x, y);
			return;
		}
		
		final camera = FlxG.camera;
		final minX:Null<Float> = minScrollX == null ? null : minScrollX - (camera.zoom - 1) * camera.width / (2 * camera.zoom);
		final maxX:Null<Float> = maxScrollX == null ? null : maxScrollX + (camera.zoom - 1) * camera.width / (2 * camera.zoom);
		final minY:Null<Float> = minScrollY == null ? null : minScrollY - (camera.zoom - 1) * camera.height / (2 * camera.zoom);
		final maxY:Null<Float> = maxScrollY == null ? null : maxScrollY + (camera.zoom - 1) * camera.height / (2 * camera.zoom);
		
		camFollow.x = FlxMath.bound(x, minX, (maxX != null) ? maxX - camera.width : null);
		camFollow.y = FlxMath.bound(y, minY, (maxY != null) ? maxY - camera.height : null);
	}
	
	public function getSongLength()
	{
		return (inst.length / inst.pitch) - Settings.globalOffset;
	}
	
	public function getTimeRemaining()
	{
		return getSongLength() - (timing.time / inst.pitch) + Settings.globalOffset;
	}
	
	public function playNoteAnim(char:Character, note:Note)
	{
		char.playNoteAnim(note, getBeatLength());
	}
	
	public function getBeatLength()
	{
		return song.getTimingPointAt(timing.audioPosition).beatLength / GameplayGlobals.playbackRate;
	}
	
	function initCameras()
	{
		FlxG.cameras.reset(new FNFCamera());
		
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);
		
		camOther = new FlxCamera();
		camOther.bgColor = 0;
		FlxG.cameras.add(camOther, false);
	}
	
	function initSong()
	{
		inst = FlxG.sound.load(Paths.getSongInst(song), 1, false, FlxG.sound.defaultMusicGroup, false, false, null, function()
		{
			instEnded = true;
			inst.volume = 0;
			inst.stop();
			inst.time = inst.length;
		});
		inst.pitch = GameplayGlobals.playbackRate;
		
		var vocalsSound = Paths.getSongVocals(song);
		if (vocalsSound != null)
			vocals = FlxG.sound.load(vocalsSound, 1, false, FlxG.sound.defaultMusicGroup, false, false, null, function()
			{
				vocals.volume = 0;
			});
		else
			vocals = FlxG.sound.list.add(new FlxSound());
		vocals.pitch = GameplayGlobals.playbackRate;
		
		timing = new MusicTiming(inst, song.timingPoints, false, song.timingPoints[0].beatLength * 5, onBeatHit, [vocals], startSong);
		timing.onStepHit.add(onStepHit);
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
				judgementDisplay.add(new JudgementDisplay(i, JudgementSkin.loadSkinFromName(Settings.playerConfigs[i].judgementSkin)));
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
		judgementCounters.cameras = [camOther];
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
			songInfoDisplay = new SongInfoDisplay(song, inst, timing);
			songInfoDisplay.cameras = [camOther];
		}
		
		lyricsDisplay = new LyricsDisplay(song, Song.getSongLyrics(song));
		lyricsDisplay.cameras = [camHUD];
	}
	
	function initPauseSubState()
	{
		pauseSubState = new PauseSubState(this);
	}
	
	function initCharacters()
	{
		if (Settings.staticBG)
		{
			staticBG = new AnimatedSprite();
			staticBG.frames = Paths.getSpritesheet('stages/static');
			staticBG.animation.addByPrefix('static', 'menuStatic_');
			staticBG.setGraphicSize(FlxG.width, FlxG.height);
			staticBG.updateHitbox();
			staticBG.playAnim('static');
			staticBG.scrollFactor.set();
			add(staticBG);
		}
		
		var gfInfo = CharacterInfo.loadCharacterFromName(song.gf);
		gf = new Character(400, 130, gfInfo, false, true);
		gf.scrollFactor.set(0.95, 0.95);
		timing.addDancingSprite(gf);
		gf.onSing.add(onCharacterSing.bind(gf));
		
		var opponentName = chars[0] != null && song.opponent.length > 0 ? chars[0] : song.opponent;
		var opponentInfo = CharacterInfo.loadCharacterFromName(opponentName);
		opponent = new Character(100, 100, opponentInfo);
		timing.addDancingSprite(opponent);
		opponent.onSing.add(onCharacterSing.bind(opponent));
		
		var bfName = chars[1] != null && song.bf.length > 0 ? chars[1] : song.bf;
		var bfInfo = CharacterInfo.loadCharacterFromName(bfName);
		bf = new Character(770, 100, bfInfo, true);
		timing.addDancingSprite(bf);
		bf.onSing.add(onCharacterSing.bind(bf));
		
		for (char in [opponent, bf])
		{
			if (char.animation.exists('intro'))
				char.playSpecialAnim('intro');
		}
		
		if (!Settings.hideHUD)
		{
			if (Settings.healthBarAlpha > 0)
			{
				var infos:Array<CharacterInfo> = [opponentInfo, bfInfo];
				healthBars = new FlxTypedGroup();
				for (i in 0...2)
					healthBars.add(new HealthBar(ruleset.playfields[i].scoreProcessor,
						infos[i] != null ? infos[i] : CharacterInfo.loadCharacterFromName(chars[i])));
				healthBars.cameras = [camHUD];
				add(healthBars);
			}
			
			add(statsDisplay);
		}
		
		add(npsDisplay);
		if (songInfoDisplay != null)
			add(songInfoDisplay);
		add(lyricsDisplay);
	}
	
	function initStage()
	{
		deathBG = new CameraBackground();
		deathBG.color = FlxColor.BLACK;
		updateBG();
		
		camFollow = new FlxObject();
		add(camFollow);
		
		var stage = song.stage;
		stageFile = new StageFile(this, stage);
		
		var stageInfo = CoolUtil.getNameInfo(stage);
		var stageScript = addScript('data/stages/' + stageInfo.name, stageInfo.mod, false);
		if (stageScript != null)
		{
			for (name => spr in stageFile.sprites)
				stageScript.set(name, spr);
			stageScript.call("onCreate");
		}
		else if (!stageFile.found)
			stageFile = new StageFile(this, 'fnf:stage');
			
		FlxG.camera.follow(camFollow, LOCKON, 0.04 * GameplayGlobals.playbackRate);
		updateCamPosition();
		FlxG.camera.snapToTarget();
		
		FlxG.camera.zoom = defaultCamZoom;
	}
	
	function initScripts()
	{
		addScriptsInFolder(song.directory);
		
		var characters = [opponent, bf, gf];
		for (char in characters)
		{
			if (char.info != null)
				addScript('data/characters/' + char.info.name, char.info.mod);
		}
		
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
		
		addScriptsInFolder(Path.join([Mods.modsPath, Mods.currentMod, 'data/globalScripts']));
		
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
			
		if (judgementDisplay != null)
		{
			for (display in judgementDisplay)
			{
				for (graphic in display.graphics)
					precacheGraphic(graphic);
			}
		}
		precacheGraphic(opponent.graphic);
		precacheGraphic(bf.graphic);
		precacheGraphic(gf.graphic);
		
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
			var lerp = (elapsed * 3 * camZoomingDecay * GameplayGlobals.playbackRate);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 1 - lerp);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 1 - lerp);
		}
	}
	
	function handleInput(elapsed:Float)
	{
		if (isPaused || hasEnded || died)
			return;
			
		ruleset.handleInput(elapsed);
		
		if (FlxG.keys.justPressed.F7)
			debugMode = true;
			
		if (debugMode)
		{
			if (FlxG.keys.justPressed.F2 && hasStarted)
				setTime(inst.time + 10000 * GameplayGlobals.playbackRate);
				
			if (FlxG.keys.justPressed.F1 && hasStarted)
			{
				killNotes();
				endSong();
			}
			
			if (FlxG.keys.justPressed.SEVEN)
			{
				exit(new SongEditorState(Song.loadSong(Path.join([song.directory, song.difficultyName + '.json'])), 0, true), true);
				return;
			}
		}
		
		if (canPause)
		{
			for (i in 0...2)
			{
				if (Controls.playerJustPressed(i, PAUSE))
				{
					isPaused = true;
					persistentUpdate = false;
					pauseSubState.setPlayer(i);
					openSubState(pauseSubState);
					callOnScripts("onPause", [i]);
					break;
				}
			}
		}
	}
	
	function onLanePressed(lane:Int, player:Int)
	{
		ruleset.playfields[player].onLanePressed(lane);
		
		callOnScripts("onLanePressed", [lane, player]);
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
			char.startDanceTimer(getBeatLength() / 1000);
		}
		
		callOnScripts("onLaneReleased", [lane, player]);
	}
	
	function onGhostTap(lane:Int, player:Int)
	{
		if (!Settings.ghostTapping)
		{
			var char = getPlayerCharacter(player);
			char.playMissAnim(lane, getBeatLength());
			
			if (Settings.missSounds)
				playMissSound();
		}
		
		callOnScripts("onGhostTap", [lane, player]);
	}
	
	function onNoteHit(note:Note, judgement:Judgement, ms:Float)
	{
		var player = note.info.player;
		ruleset.playfields[player].onNoteHit(note, judgement);
		
		if (!note.noAnim)
		{
			var char = getNoteCharacter(note);
			if (note.heyNote)
				char.playSpecialAnim('hey', 0.6 / GameplayGlobals.playbackRate, true);
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
					char.startDanceTimer(getBeatLength() / 1000);
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
		
		if (!hitNote)
			camZooming = camBop = hitNote = true;
			
		callOnScripts("onNoteHit", [note, judgement, ms]);
	}
	
	function onNoteMissed(note:Note)
	{
		if (!note.noMissAnim)
		{
			var char = getNoteCharacter(note);
			char.playMissAnim(note.info.playerLane, getBeatLength());
		}
		
		if (Settings.missSounds)
			playMissSound();
			
		if (!hitNote)
			camZooming = camBop = hitNote = true;
			
		callOnScripts("onNoteMissed", [note]);
	}
	
	function onNoteReleased(note:Note, judgement:Judgement, ms:Float)
	{
		var player = note.info.player;
		msDisplay.members[player].showMS(ms, judgement);
		
		callOnScripts("onNoteReleased", [note, judgement, ms]);
	}
	
	function onNoteReleaseMissed(note:Note)
	{
		if (!note.noMissAnim)
		{
			var char = getNoteCharacter(note);
			char.playMissAnim(note.info.playerLane, getBeatLength());
		}
		
		if (Settings.missSounds)
			playMissSound();
			
		callOnScripts("onNoteReleaseMissed", [note]);
	}
	
	function onJudgementAdded(judgement:Judgement, player:Int)
	{
		if (judgementDisplay != null)
			judgementDisplay.members[player].showJudgement(judgement);
			
		judgementCounters.members[player].updateText();
		
		callOnScripts("onJudgementAdded", [judgement, player]);
	}
	
	function onNoteSpawned(note:Note)
	{
		callOnScripts("onNoteSpawned", [note]);
	}
	
	function onCharacterSing(char:Character, lane:Int, hold:Bool)
	{
		callOnScripts("onCharacterSing", [char, lane, hold]);
	}
	
	function startCountdown()
	{
		new FlxTimer().start(song.timingPoints[0].beatLength / 1000, function(tmr)
		{
			var count = tmr.elapsedLoops - 1;
			if (count > 0)
				readySetGo('countdown/' + introSprPaths[count - 1]);
			FlxG.sound.play(Paths.getSound('countdown/' + introSndPaths[count]), 0.6);
			
			callOnScripts("onCountdownTick", [count]);
		}, 4);
		
		callOnScripts("onStartCountdown");
	}
	
	function readySetGo(path:String):Void
	{
		var spr = new FlxSprite(0, 0, Paths.getImage(path));
		spr.scrollFactor.set();
		spr.screenCenter();
		spr.cameras = [camHUD];
		spr.antialiasing = Settings.antialiasing;
		add(spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, song.timingPoints[0].beatLength / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(_)
			{
				spr.destroy();
			}
		});
		
		callOnScripts("onReadySetGo", [spr]);
	}
	
	function getEventEarlyTrigger(event:PlayStateEvent)
	{
		var value:Dynamic = callOnScripts("getEventEarlyTrigger", [event]);
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
			
		callOnScripts("onStepHit", [step, decStep]);
	}
	
	function onBeatHit(beat:Int, decBeat:Float)
	{
		if (hasEnded)
			return;
			
		if (healthBars != null && iconBop)
		{
			for (bar in healthBars)
				bar.onBeatHit();
		}
		
		if (camBopRate != null && camBopRate > 0 && beat % camBopRate == 0)
			doCamBop();
			
		callOnScripts("onBeatHit", [beat, decBeat]);
	}
	
	function onBarHit(bar:Int, decBar:Float)
	{
		if (hasEnded)
			return;
			
		if (camBopRate == null)
			doCamBop();
			
		callOnScripts("onBarHit", [bar, decBar]);
	}
	
	public function doCamBop()
	{
		if (Settings.camZooming && camZooming && camBop)
		{
			FlxG.camera.zoom += 0.015 * camBopMult;
			camHUD.zoom += 0.03 * camBopMult;
		}
	}
	
	function updateBG()
	{
		if (staticBG == null)
			return;
			
		final camWidth = Math.ceil(FlxG.camera.viewWidth);
		final camHeight = Math.ceil(FlxG.camera.viewHeight);
		
		staticBG.setPosition(FlxG.camera.viewMarginX, FlxG.camera.viewMarginY);
		if (staticBG.width != camWidth || staticBG.height != camHeight)
		{
			staticBG.setGraphicSize(camWidth, camHeight);
			staticBG.updateHitbox();
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
		
		var char = getPlayerCharacter(player);
		if (char.allowDanceTimer.active)
			char.allowDanceTimer.cancel();
		for (timer in char.holdTimers)
		{
			if (timer != null && timer.active)
				timer.cancel();
		}
		char.stopAnimCallback();
		if (!disableCamFollow)
			focusOnChar(char);
		char.angularVelocity = 360;
		char.x -= char.offset.x;
		char.y -= char.offset.y;
		char.offset.set();
		FlxTween.tween(char.scale, {x: 0, y: 0}, 0.8, {
			onComplete: function(_)
			{
				char.visible = false;
			}
		});
		
		for (playfield in ruleset.playfields)
			playfield.visible = false;
			
		if (deathTimer == null)
			deathTimer = new FlxTimer().start(2, function(_)
			{
				endSong();
			});
			
		FlxG.camera.flash(FlxColor.WHITE, 0.5);
		FlxG.sound.play(Paths.getSound('death/default'));
		
		callOnScripts("onDeath", [player]);
	}
	
	function checkDeath()
	{
		if (died || !hasStarted || hasEnded)
			return;
			
		for (i in 0...2)
		{
			var score = ruleset.playfields[i].scoreProcessor;
			if (Controls.playerJustPressed(i, RESET) && !Settings.playerConfigs[i].noReset)
				score.forceFail = true;
			if (score.failed)
				onDeath(i);
		}
	}
	
	function playMissSound()
	{
		FlxG.sound.play(Paths.getSound('miss/missnote' + FlxG.random.int(1, 3)), FlxG.random.float(0.1, 0.2));
	}
	
	function setTime(time:Float)
	{
		timing.setTime(time);
		ruleset.handleSkip();
		callOnScripts("onSetTime", [time]);
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
		
		return timing.audioPosition > inst.length;
	}
}

typedef PlayStateEvent =
{
	var startTime:Float;
	var event:String;
	var params:Array<String>;
}
