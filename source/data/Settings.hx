package data;

import flixel.FlxG;

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
	// Audio
	public static var musicVolume:Float = 1;
	public static var effectVolume:Float = 1;
	public static var globalOffset:Int = 0;
	public static var smoothAudioTiming:Bool = false;
	// Miscellaneous
	public static var autoPause:Bool = false;
	// Ruleset
	public static var singleSongSelection:Bool = false;
	public static var playbackRate:Float = 1;
	public static var randomEvents:Bool = true;
	public static var canDie:Bool = true;
	public static var winCondition:WinCondition = SCORE;

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
		load('masterVolume');
		load('musicVolume');
		load('effectVolume');
		load('globalOffset');
		load('smoothAudioTiming');
		load('autoPause');
		load('singleSongSelection');
		load('playbackRate');
		load('randomEvents');
		load('canDie');
		load('winCondition');

		if (!FlxG.fullscreen)
		{
			FlxG.resizeWindow(Math.round(FlxG.width * resolution), Math.round(FlxG.height * resolution));
		}
		FlxG.setFramerate(fpsCap);
		FlxG.forceNoAntialiasing = !antialiasing;
		Main.updateFilters();

		FlxG.sound.defaultMusicGroup.volume = musicVolume;
		FlxG.sound.defaultSoundGroup.volume = effectVolume;

		FlxG.autoPause = autoPause;
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
		save('masterVolume');
		save('musicVolume');
		save('effectVolume');
		save('globalOffset');
		save('smoothAudioTiming');
		save('autoPause');
		save('singleSongSelection');
		save('playbackRate');
		save('randomEvents');
		save('canDie');
		save('winCondition');

		FlxG.save.flush();
	}

	static function load(variable:String)
	{
		var data = Reflect.field(FlxG.save.data, variable);
		if (data != null)
			Reflect.setProperty(Settings, variable, data);
	}

	static function save(variable:String)
	{
		Reflect.setField(FlxG.save.data, variable, Reflect.getProperty(Settings, variable));
	}
}

@:enum abstract FilterType(String) from String to String
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

@:enum abstract WinCondition(String) from String to String
{
	var SCORE = 'Highest Score';
	var ACCURACY = 'Highest Accuracy';
	var MISSES = 'Least Misses';
}
