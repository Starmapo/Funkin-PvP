package data;

import flixel.FlxG;

@:keep
class Settings
{
	// Audio
	public static var musicVolume:Float = 1;
	public static var effectVolume:Float = 1;
	public static var globalOffset:Int = 0;
	public static var smoothAudioTiming:Bool = false;

	public static function loadData()
	{
		load('musicVolume');
		load('effectVolume');
		load('globalOffset');
		load('smoothAudioTiming');

		FlxG.sound.defaultMusicGroup.volume = musicVolume;
		FlxG.sound.defaultSoundGroup.volume = effectVolume;
	}

	public static function saveData()
	{
		save('musicVolume');
		save('effectVolume');
		save('globalOffset');
		save('smoothAudioTiming');

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
