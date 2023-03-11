package data;

import flixel.FlxG;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

@:keep
class Settings
{
	// Players
	public static var playerConfigs:Array<PlayerConfig>;
	// Video
	public static var resolution:Float = 1;
	public static var fpsCap:Int = 60;
	public static var hue:Int = 0;
	public static var brightness:Int = 0;
	public static var gamma:Float = 1;
	public static var filter:FilterType = NONE;
	// Audio
	public static var musicVolume:Float = 1;
	public static var effectVolume:Float = 1;
	public static var globalOffset:Int = 0;
	public static var smoothAudioTiming:Bool = false;

	public static function loadData()
	{
		load('playerConfigs');
		load('resolution');
		load('fpsCap');
		load('hue');
		load('brightness');
		load('gamma');
		load('filter');
		load('masterVolume');
		load('musicVolume');
		load('effectVolume');
		load('globalOffset');
		load('smoothAudioTiming');

		if (!FlxG.fullscreen)
		{
			FlxG.resizeWindow(Math.round(FlxG.width * resolution), Math.round(FlxG.height * resolution));
		}
		FlxG.setFramerate(fpsCap);
		updateFilters();

		FlxG.sound.defaultMusicGroup.volume = musicVolume;
		FlxG.sound.defaultSoundGroup.volume = effectVolume;
	}

	public static function saveData()
	{
		save('playerConfigs');
		save('resolution');
		save('fpsCap');
		save('hue');
		save('brightness');
		save('gamma');
		save('filter');
		save('masterVolume');
		save('musicVolume');
		save('effectVolume');
		save('globalOffset');
		save('smoothAudioTiming');

		FlxG.save.flush();
	}

	public static function updateFilters()
	{
		var filters:Array<BitmapFilter> = [];

		var matrix = switch (filter)
		{
			case NONE:
				[
					1 * gamma,         0,         0, 0, brightness,
					        0, 1 * gamma,         0, 0, brightness,
					        0,         0, 1 * gamma, 0, brightness,
					        0,         0,         0, 1,          0,
				];
			case DEUTERANOPIA:
				[
					0.43 * gamma, 0.72 * gamma, -.15 * gamma, 0, brightness,
					0.34 * gamma, 0.57 * gamma, 0.09 * gamma, 0, brightness,
					-.02 * gamma, 0.03 * gamma,    1 * gamma, 0, brightness,
					           0,            0,            0, 1,          0,
				];
			case PROTANOPIA:
				[
					0.20 * gamma, 0.99 * gamma, -.19 * gamma, 0, brightness,
					0.16 * gamma, 0.79 * gamma, 0.04 * gamma, 0, brightness,
					0.01 * gamma, -.01 * gamma,    1 * gamma, 0, brightness,
					           0,            0,            0, 1,          0,
				];
			case TRITANOPIA:
				[
					0.20 * gamma, 0.99 * gamma, -.19 * gamma, 0, brightness,
					0.16 * gamma, 0.79 * gamma, 0.04 * gamma, 0, brightness,
					0.01 * gamma, -.01 * gamma,    1 * gamma, 0, brightness,
					           0,            0,            0, 1,          0,
				];
		}
		filters.push(new ColorMatrixFilter(matrix));
		filters.push(new ColorMatrixFilter(getHueMatrix()));

		FlxG.game.filtersEnabled = true;
		FlxG.game.setFilters(filters);
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

	static function getHueMatrix()
	{
		var cosA:Float = Math.cos(-hue * Math.PI / 180);
		var sinA:Float = Math.sin(-hue * Math.PI / 180);

		var a1:Float = cosA + (1.0 - cosA) / 3.0;
		var a2:Float = 1.0 / 3.0 * (1.0 - cosA) - Math.sqrt(1.0 / 3.0) * sinA;
		var a3:Float = 1.0 / 3.0 * (1.0 - cosA) + Math.sqrt(1.0 / 3.0) * sinA;

		var b1:Float = a3;
		var b2:Float = cosA + 1.0 / 3.0 * (1.0 - cosA);
		var b3:Float = a2;

		var c1:Float = a2;
		var c2:Float = a3;
		var c3:Float = b2;

		return [
			a1, b1, c1, 0, 0,
			a2, b2, c2, 0, 0,
			a3, b3, c3, 0, 0,
			 0,  0,  0, 1, 0
		];
	}
}

@:enum abstract FilterType(String) from String to String
{
	var NONE = "None";
	var DEUTERANOPIA = "Deuteranopia";
	var PROTANOPIA = "Protanopia";
	var TRITANOPIA = "Tritanopia";
}
