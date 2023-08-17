package backend.settings;

import backend.bindable.Bindable;
import backend.bindable.BindableFloat;
import backend.game.Judgement;
import backend.settings.PlayerConfig.PlayerConfigDevice;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;

@:keep
class Settings
{
	// Players
	public static var playerConfigs:Array<PlayerConfig>;
	// Video
	public static var resolution:Float = 1;
	public static var fpsCap:Int = 60;
	public static var vsync:Bool = false;
	public static var antialiasing:Bool = true;
	public static var hue:Int = 0;
	public static var brightness:Int = 0;
	public static var gamma:Float = 1;
	public static var filter:FilterType = NONE;
	public static var flashing:Bool = false;
	// Audio
	public static var musicVolume:Float = 1;
	public static var effectVolume:Float = 1;
	public static var globalOffset:Int = 0;
	public static var smoothAudioTiming:Bool = false;
	// Gameplay
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true;
	public static var staticBG:Bool = true;
	public static var backgroundBrightness:Float = 1;
	public static var hideHUD:Bool = false;
	public static var timeDisplay:TimeDisplay = TIME_ELAPSED;
	public static var healthBarAlpha:Float = 1;
	public static var healthBarColors:Bool = true;
	public static var breakTransparency:Bool = true;
	public static var cameraNoteMovements:Bool = true;
	public static var missSounds:Bool = true;
	public static var camZooming:Bool = true;
	public static var resultsScreen:Bool = true;
	public static var clearGameplayCache:Bool = true;
	// Miscellaneous
	public static var autoPause:Bool = false;
	public static var fastTransitions:Bool = false;
	public static var showInternalNotifications:Bool = true;
	public static var reloadMods:Bool = false;
	public static var checkForUpdates:Bool = true;
	public static var forceCacheReset:Bool = false;
	// Ruleset
	public static var singleSongSelection:Bool = false;
	public static var playbackRate:Float = 1;
	public static var noSliderVelocity:Bool = false;
	public static var mirrorNotes:Bool = false;
	public static var noLongNotes:Bool = false;
	public static var fullLongNotes:Bool = false;
	public static var inverse:Bool = false;
	public static var randomize:Bool = false;
	public static var ghostTapping:Bool = true;
	public static var marvWindow:Int = 23;
	public static var sickWindow:Int = 57;
	public static var goodWindow:Int = 101;
	public static var badWindow:Int = 141;
	public static var shitWindow:Int = 169;
	public static var missWindow:Int = 218;
	public static var comboBreakJudgement:Judgement = MISS;
	public static var randomEvents:Bool = true;
	public static var canDie:Bool = true;
	public static var healthGain:Float = 1;
	public static var healthLoss:Float = 1;
	public static var noMiss:Bool = false;
	public static var winCondition:WinCondition = SCORE;
	// Editor
	public static var editorScrollSpeed:BindableFloat = new BindableFloat(0.8, 0.25, 5);
	public static var editorScaleSpeedWithRate:Bindable<Bool> = new Bindable(true);
	public static var editorLongNoteAlpha:BindableFloat = new BindableFloat(1, 0.3, 1);
	public static var editorHitsoundVolume:BindableFloat = new BindableFloat(1, 0, 1);
	public static var editorOpponentHitsounds:Bindable<Bool> = new Bindable(true);
	public static var editorBFHitsounds:Bindable<Bool> = new Bindable(true);
	public static var editorLiveMapping:Bindable<Bool> = new Bindable(true);
	public static var editorPlaceOnNearestTick:Bindable<Bool> = new Bindable(true);
	public static var editorInstVolume:BindableFloat = new BindableFloat(1, 0, 1);
	public static var editorVocalsVolume:BindableFloat = new BindableFloat(1, 0, 1);
	public static var editorSaveOnExit:Bindable<Bool> = new Bindable(true);
	public static var editorMetronome:Bindable<MetronomeType> = new Bindable(MetronomeType.NONE);
	
	public static var defaultValues:Map<String, Dynamic> = new Map();
	
	static var fields:Array<String>;
	
	public static function loadData()
	{
		if (fields == null)
			initFields();
			
		for (f in fields)
		{
			var field = Reflect.getProperty(Settings, f);
			if (Std.isOfType(field, Bindable))
				loadBindable(f);
			else
				load(f);
		}
		
		if (FlxG.save.data.fullscreen != null)
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		if (!FlxG.fullscreen)
			FlxG.resizeWindow(Math.round(FlxG.width * resolution), Math.round(FlxG.height * resolution));
		CoolUtil.setFramerate(fpsCap);
		Application.current.window.vsync = vsync;
		Main.updateFilters();
		
		FlxG.sound.defaultMusicGroup.volume = musicVolume;
		FlxG.sound.defaultSoundGroup.volume = effectVolume;
		
		FlxG.autoPause = autoPause;
		FlxTransitionableState.defaultTransOut.duration = FlxTransitionableState.defaultTransIn.duration = Main.getTransitionTime();
		
		checkPlayerConfigs();
	}
	
	public static function saveData()
	{
		if (fields == null)
			initFields();
			
		for (f in fields)
		{
			var field = Reflect.getProperty(Settings, f);
			if (Std.isOfType(field, Bindable))
				saveBindable(f);
			else
				save(f);
		}
		
		FlxG.save.flush();
	}
	
	static function load(variable:String)
	{
		var data = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			Reflect.setProperty(Settings, variable, data);
	}
	
	static function loadBindable(variable:String)
	{
		var bindable:Bindable<Any> = Reflect.getProperty(Settings, variable);
		
		var data = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			bindable.value = data;
	}
	
	static function save(variable:String)
	{
		Reflect.setField(FlxG.save.data, variable, Reflect.getProperty(Settings, variable));
	}
	
	static function saveBindable(variable:String)
	{
		var bindable:Bindable<Any> = Reflect.getProperty(Settings, variable);
		Reflect.setField(FlxG.save.data, variable, bindable.value);
	}
	
	static function initFields()
	{
		var daFields = Type.getClassFields(Settings);
		daFields.remove('fields');
		daFields.remove('defaultValues');
		var i = daFields.length - 1;
		while (i >= 0)
		{
			var f = daFields[i];
			var field = Reflect.getProperty(Settings, f);
			if (Reflect.isFunction(field))
				daFields.remove(f);
			else
			{
				if (Std.isOfType(field, Bindable))
				{
					var bindable:Bindable<Any> = cast field;
					defaultValues.set(f, bindable.value);
				}
				else
					defaultValues.set(f, field);
			}
			
			i--;
		}
		fields = daFields;
	}
	
	static function checkPlayerConfigs()
	{
		if (Settings.playerConfigs == null)
		{
			var playerConfigs:Array<PlayerConfig> = [createDefaultConfig(KEYBOARD)];
			
			var foundGamepad:Bool = false;
			for (i in 0...FlxG.gamepads.numActiveGamepads)
			{
				var gamepad = FlxG.gamepads.getByID(i);
				if (gamepad != null && gamepad.connected)
				{
					playerConfigs.push(createDefaultConfig(GAMEPAD(gamepad.id)));
					foundGamepad = true;
					break;
				}
			}
			if (!foundGamepad)
				playerConfigs.push(createDefaultConfig(NONE));
				
			Settings.playerConfigs = playerConfigs;
			Settings.saveData();
		}
		
		for (config in Settings.playerConfigs)
		{
			if (config.scrollSpeed == null)
				config.scrollSpeed = 1;
			if (config.downScroll == null)
				config.downScroll = false;
			if (config.judgementCounter == null)
				config.judgementCounter = false;
			if (config.npsDisplay == null)
				config.npsDisplay = false;
			if (config.msDisplay == null)
				config.msDisplay = false;
			if (config.noteSplashes == null)
				config.noteSplashes = true;
			if (config.noReset == null)
				config.noReset = false;
			if (config.autoplay == null)
				config.autoplay = false;
			if (config.transparentReceptors == null)
				config.transparentReceptors = false;
			if (config.transparentHolds == null)
				config.transparentHolds = false;
			if (config.notesScale == null)
				config.notesScale = 1;
			if (config.noteSkin == null)
				config.noteSkin = 'fnf:default';
			if (config.judgementSkin == null)
				config.judgementSkin = 'fnf:default';
			if (config.splashSkin == null)
				config.splashSkin = 'fnf:default';
		}
	}
	
	static function createDefaultConfig(device:PlayerConfigDevice):PlayerConfig
	{
		return {
			device: device,
			controls: Controls.getDefaultControls(device)
		};
	}
}

enum abstract FilterType(String) from String to String
{
	var NONE = "None";
	// Colorblindness filters come first
	var DEUTERANOPIA = "Deuteranopia";
	var PROTANOPIA = "Protanopia";
	var TRITANOPIA = "Tritanopia";
	// Now the ones just for fun
	var DOWNER = "Downer";
	var GAME_BOY = "Game Boy";
	var GRAYSCALE = "Grayscale";
	var INVERT = "Invert";
	var VIRTUAL_BOY = "Virtual Boy";
}

enum abstract WinCondition(String) from String to String
{
	var SCORE = 'Highest Score';
	var ACCURACY = 'Highest Accuracy';
	var MISSES = 'Least Misses';
}

enum abstract MetronomeType(String) from String to String
{
	var NONE = 'None';
	var EVERY_BEAT = 'Every Beat';
	var EVERY_HALF_BEAT = 'Every Half Beat';
}

enum abstract TimeDisplay(String) from String to String
{
	var TIME_ELAPSED = 'Time Elapsed';
	var TIME_LEFT = 'Time Left';
	var PERCENTAGE = 'Percentage Progress';
	var DISABLED = 'Disabled';
}
