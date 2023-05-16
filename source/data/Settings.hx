package data;

import flixel.FlxG;
import util.bindable.Bindable;
import util.bindable.BindableFloat;
import util.bindable.BindableInt;

@:keep
class Settings
{
	// Players
	public static var playerConfigs:Array<PlayerConfig>;
	// Video
	public static var resolution:Float = 1;
	public static var fpsCap:Int = 60;
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
	public static var hideHUD:Bool = false;
	public static var timeDisplay:TimeDisplay = TIME_ELAPSED;
	public static var camZooming:Bool = true;
	public static var clearGameplayCache:Bool = true;
	// Miscellaneous
	public static var autoPause:Bool = false;
	public static var persistentCache:Bool = true;
	// Ruleset
	public static var singleSongSelection:Bool = false;
	public static var playbackRate:Float = 1;
	public static var noSliderVelocity:Bool = false;
	public static var randomEvents:Bool = true;
	public static var canDie:Bool = true;
	public static var noMiss:Bool = false;
	public static var winCondition:WinCondition = SCORE;
	// Editor
	public static var editorScrollSpeed:BindableFloat;
	public static var editorScaleSpeedWithRate:Bindable<Bool>;
	public static var editorLongNoteAlpha:BindableFloat;
	public static var editorHitsoundVolume:BindableFloat;
	public static var editorOpponentHitsounds:Bindable<Bool>;
	public static var editorBFHitsounds:Bindable<Bool>;
	public static var editorLiveMapping:Bindable<Bool>;
	public static var editorPlaceOnNearestTick:Bindable<Bool>;
	public static var editorInstVolume:BindableFloat;
	public static var editorVocalsVolume:BindableFloat;
	public static var editorSaveOnExit:Bindable<Bool>;
	public static var editorMetronome:Bindable<MetronomeType>;

	public static function loadData()
	{
		load('playerConfigs');
		load('resolution');
		load('fpsCap');
		load('antialiasing');
		load('hue');
		load('brightness');
		load('gamma');
		load('filter');
		load('flashing');
		load('masterVolume');
		load('musicVolume');
		load('effectVolume');
		load('globalOffset');
		load('smoothAudioTiming');
		load('lowQuality');
		load('shaders');
		load('hideHUD');
		load('timeDisplay');
		load('camZooming');
		load('clearGameplayCache');
		load('autoPause');
		load('persistentCache');
		load('singleSongSelection');
		load('playbackRate');
		load('noSliderVelocity');
		load('randomEvents');
		load('canDie');
		load('noMiss');
		load('winCondition');
		loadBindableFloat('editorScrollSpeed', 0.8, 0.25, 5);
		loadBindable('editorScaleSpeedWithRate', true);
		loadBindableFloat('editorLongNoteAlpha', 1, 0.3, 1);
		loadBindableFloat('editorHitsoundVolume', 1, 0, 1);
		loadBindable('editorOpponentHitsounds', true);
		loadBindable('editorBFHitsounds', true);
		loadBindable('editorLiveMapping', true);
		loadBindable('editorPlaceOnNearestTick', true);
		loadBindableFloat('editorInstVolume', 1, 0, 1);
		loadBindableFloat('editorVocalsVolume', 1, 0, 1);
		loadBindable('editorSaveOnExit', true);
		loadBindable('editorMetronome', MetronomeType.NONE);

		if (!FlxG.fullscreen)
			FlxG.resizeWindow(Math.round(FlxG.width * resolution), Math.round(FlxG.height * resolution));
		FlxG.setFramerate(fpsCap);
		FlxG.forceNoAntialiasing = !antialiasing;
		Main.updateFilters();

		FlxG.sound.defaultMusicGroup.volume = musicVolume;
		FlxG.sound.defaultSoundGroup.volume = effectVolume;

		FlxG.autoPause = autoPause;

		for (config in playerConfigs)
		{
			if (config.scrollSpeed == null)
				config.scrollSpeed = 0.75;
			if (config.noteSplashes == null)
				config.noteSplashes = true;
			if (config.autoplay == null)
				config.autoplay = false;
		}
	}

	public static function saveData()
	{
		save('playerConfigs');
		save('resolution');
		save('fpsCap');
		save('antialiasing');
		save('hue');
		save('brightness');
		save('gamma');
		save('filter');
		save('flashing');
		save('masterVolume');
		save('musicVolume');
		save('effectVolume');
		save('globalOffset');
		save('smoothAudioTiming');
		save('lowQuality');
		save('shaders');
		save('hideHUD');
		save('timeDisplay');
		save('camZooming');
		save('clearGameplayCache');
		save('autoPause');
		save('persistentCache');
		save('singleSongSelection');
		save('playbackRate');
		save('noSliderVelocity');
		save('randomEvents');
		save('canDie');
		save('noMiss');
		save('winCondition');
		saveBindable('editorScrollSpeed');
		saveBindable('editorScaleSpeedWithRate');
		saveBindable('editorLongNoteAlpha');
		saveBindable('editorHitsoundVolume');
		saveBindable('editorOpponentHitsounds');
		saveBindable('editorBFHitsounds');
		saveBindable('editorLiveMapping');
		saveBindable('editorPlaceOnNearestTick');
		saveBindable('editorInstVolume');
		saveBindable('editorVocalsVolume');
		saveBindable('editorSaveOnExit');
		saveBindable('editorMetronome');

		FlxG.save.flush();
	}

	static function load(variable:String)
	{
		var data = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			Reflect.setProperty(Settings, variable, data);
	}

	static function loadBindable<T>(variable:String, defaultValue:T)
	{
		var bindable = new Bindable(defaultValue);

		var data:Null<T> = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			bindable.value = data;

		Reflect.setProperty(Settings, variable, bindable);
	}

	static function loadBindableInt(variable:String, defaultValue:Int, minValue:Int, maxValue:Int)
	{
		var bindable = new BindableInt(defaultValue, minValue, maxValue);

		var data:Null<Int> = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			bindable.value = data;

		Reflect.setProperty(Settings, variable, bindable);
	}

	static function loadBindableFloat(variable:String, defaultValue:Float, minValue:Float, maxValue:Float)
	{
		var bindable = new BindableFloat(defaultValue, minValue, maxValue);

		var data:Null<Float> = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			bindable.value = data;

		Reflect.setProperty(Settings, variable, bindable);
	}

	static function save(variable:String)
	{
		Reflect.setField(FlxG.save.data, variable, Reflect.getProperty(Settings, variable));
	}

	static function saveBindable<T>(variable:String)
	{
		var bindable:Bindable<T> = Reflect.getProperty(Settings, variable);
		Reflect.setField(FlxG.save.data, variable, bindable.value);
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
