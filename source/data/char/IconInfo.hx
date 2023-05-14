package data.char;

import haxe.io.Path;

class IconInfo extends JsonObject
{
	public static function loadIcon(path:String, ?mod:String)
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		var iconInfo = new IconInfo(json);
		iconInfo.directory = Path.normalize(Path.directory(path));
		iconInfo.iconName = new Path(path).file;
		iconInfo.mod = iconInfo.directory.split('/')[1];
		return iconInfo;
	}

	public static function loadIconFromName(name:String)
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = 'mods/${nameInfo.mod}/data/icons/${nameInfo.name}.json';
			if (Paths.exists(path))
				return loadIcon(path);
		}

		var path = 'mods/${Mods.currentMod}/data/icons/$name.json';
		if (Paths.exists(path))
			return loadIcon(path);

		return loadIcon('mods/fnf/data/icons/$name.json');
	}

	public var frames:Int;
	public var antialiasing:Bool;
	public var positionOffset:Array<Float>;
	public var normalAnim:String;
	public var normalFPS:Float;
	public var losingAnim:String;
	public var losingFPS:Float;
	public var losingOffset:Array<Float>;
	public var winningAnim:String;
	public var winningFPS:Float;
	public var winningOffset:Array<Float>;
	public var directory:String = '';
	public var iconName:String = '';
	public var mod:String = '';

	public function new(data:Dynamic)
	{
		frames = readInt(data.frames, 2, 1, 3);
		antialiasing = readBool(data.antialiasing, true);
		positionOffset = readFloatArray(data.positionOffset, [0, 0], null, 2, null, null, 2);
		normalAnim = readString(data.normalAnim);
		normalFPS = readFloat(data.normalFPS, 24, 0, 1000, 2);
		losingAnim = readString(data.losingAnim);
		losingFPS = readFloat(data.losingFPS, 24, 0, 1000, 2);
		losingOffset = readFloatArray(data.losingOffset, [], null, 2, null, null, 2);
		winningAnim = readString(data.winningAnim);
		winningFPS = readFloat(data.winningFPS, 24, 0, 1000, 2);
		winningOffset = readFloatArray(data.winningOffset, [], null, 2, null, null, 2);
	}
}
