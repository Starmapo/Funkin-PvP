package data;

import flixel.FlxG;

@:keep
class Settings
{
	public static var smoothAudioTiming:Bool = false;
	public static var globalOffset:Int = 0;

	public static function loadData()
	{
		load('smoothAudioTiming');
		load('globalOffset');
	}

	public static function saveData()
	{
		save('smoothAudioTiming');
		save('globalOffset');
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
