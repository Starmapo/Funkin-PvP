package data.skin;

import haxe.io.Path;

/**
	JSON info for a judgement skin.
**/
class JudgementSkin extends JsonObject
{
	/**
		Loads a judgement skin from a path to a JSON file.

		@return	A new `JudgementSkin` object, or `null` if the path doesn't exist or if the JSON file couldn't be parsed.
	**/
	public static function loadSkin(path:String, ?mod:String):JudgementSkin
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		var skin = new JudgementSkin(json);
		skin.directory = Path.normalize(Path.directory(path));
		skin.name = new Path(path).file;
		skin.mod = skin.directory.split('/')[1];
		return skin;
	}

	/**
		Loads a judgement skin from a name.

		@param	name	The name of the skin to load. If it contains a colon `:`, it will use the name before it as
						the mod directory.
		@return	A new `JudgementSkin` object, or `null` if the file couldn't be found or if the JSON file couldn't be
				parsed.
	**/
	public static function loadSkinFromName(name:String):JudgementSkin
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = Paths.getPath('data/judgementSkins/${nameInfo.name}.json', nameInfo.mod);
			if (Paths.exists(path))
				return loadSkin(path);
		}

		var path = Paths.getPath('data/judgementSkins/$name.json');
		if (Paths.exists(path))
			return loadSkin(path);

		return loadSkin(Paths.getPath('data/judgementSkins/$name.json', 'fnf'));
	}

	/**
		The scaling factor for the sprites. Defaults to `1`.
	**/
	public var scale:Float;

	/**
		Whether or not the sprites have antialiasing. Defaults to `true`.
	**/
	public var antialiasing:Bool;

	/**
		The full directory path this judgement skin was in.
	**/
	public var directory:String = '';

	/**
		The name of the judgement skin.
	**/
	public var name:String = '';

	/**
		The mod directory this judgement skin was in.
	**/
	public var mod:String = '';

	/**
		@param	data	The JSON file to parse data from.
	**/
	public function new(data:Dynamic)
	{
		scale = readFloat(data.scale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}
}
