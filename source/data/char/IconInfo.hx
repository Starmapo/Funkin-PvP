package data.char;

import haxe.io.Path;

/**
	JSON info for an icon.
**/
class IconInfo extends JsonObject
{
	/**
		Loads an icon file from a path to a JSON file.

		@return	A new `IconInfo` object, or `null` if the path doesn't exist or if the JSON file couldn't be parsed.
	**/
	public static function loadIcon(path:String, ?mod:String)
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		var iconInfo = new IconInfo(json);
		iconInfo.directory = Path.normalize(Path.directory(path));
		iconInfo.name = new Path(path).file;
		iconInfo.mod = iconInfo.directory.split('/')[1];
		return iconInfo;
	}

	/**
		Loads an icon file from a name.

		@param	name	The name of the icon to load. If it contains a colon `:`, it will use the name before it as the mod
						directory.
		@return	A new `IconInfo` object, or `null` if the file couldn't be found or if the JSON file couldn't be
				parsed.
	**/
	public static function loadIconFromName(name:String)
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = Paths.getPath('data/icons/${nameInfo.name}.json', nameInfo.mod);
			if (Paths.exists(path))
				return loadIcon(path);
		}

		var path = Paths.getPath('data/icons/$name.json');
		if (Paths.exists(path))
			return loadIcon(path);

		return loadIcon(Paths.getPath('data/icons/$name.json', 'fnf'));
	}

	/**
		Optional name of the image file for this icon. If unspecified, will try to find it in the `icons/` folder.
	**/
	public var image:String;

	/**
		How many frames this icon has. `1` has just the normal expression, `2` adds the losing expression, and `3` adds the
		winning expression. Defaults to `2`.
	**/
	public var frames:Int;

	/**
		Whether or not the icon should have antialiasing. Defaults to `true`.
	**/
	public var antialiasing:Bool;

	/**
		The position offset for this icon. Will be automatically flipped when playing on the right side.
	**/
	public var positionOffset:Array<Float>;

	/**
		The name of the normal animation for the icon. Only used for spritesheets.
	**/
	public var normalAnim:String;

	/**
		The frame rate, or frames per second, of the normal animation for the icon. Only used for spritesheets.
	**/
	public var normalFPS:Float;

	/**
		The name of the losing animation for the icon. Only used for spritesheets.
	**/
	public var losingAnim:String;

	/**
		The frame rate, or frames per second, of the losing animation for the icon. Only used for spritesheets.
	**/
	public var losingFPS:Float;

	/**
		The visual offset for the losing animation.

		Values are substracted, so a value of `[5, -10]` will move the graphic 5 pixels left and 10 pixels down.

		Will be automatically flipped when playing on the right side.
	**/
	public var losingOffset:Array<Float>;

	/**
		The name of the winning animation for the icon. Only used for spritesheets.
	**/
	public var winningAnim:String;

	/**
		The frame rate, or frames per second, of the winning animation for the icon. Only used for spritesheets.
	**/
	public var winningFPS:Float;

	/**
		The visual offset for the winning animation.
		
		Values are substracted, so a value of `[5, -10]` will move the graphic 5 pixels left and 10 pixels down.
		
		Will be automatically flipped when playing on the right side.
	**/
	public var winningOffset:Array<Float>;

	/**
		The full directory path this icon was in.
	**/
	public var directory:String = '';

	/**
		The name of the icon.
	**/
	public var name:String = '';

	/**
		The mod directory this icon was in.
	**/
	public var mod:String = '';

	/**
		@param	data	The JSON file to parse data from.
	**/
	public function new(data:Dynamic)
	{
		image = readString(data.image);
		frames = readInt(data.frames, 2, 1, 3);
		antialiasing = readBool(data.antialiasing, true);
		positionOffset = readFloatArray(data.positionOffset, [0, 0], null, 2, null, null, 2);
		normalAnim = readString(data.normalAnim);
		normalFPS = readFloat(data.normalFPS, 0, 0, 1000, 2);
		losingAnim = readString(data.losingAnim);
		losingFPS = readFloat(data.losingFPS, 0, 0, 1000, 2);
		losingOffset = readFloatArray(data.losingOffset, [], null, 2, null, null, 2);
		winningAnim = readString(data.winningAnim);
		winningFPS = readFloat(data.winningFPS, 0, 0, 1000, 2);
		winningOffset = readFloatArray(data.winningOffset, [], null, 2, null, null, 2);
	}
}
