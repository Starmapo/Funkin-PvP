package data.skin;

import flixel.util.FlxDestroyUtil;
import haxe.io.Path;

/**
	JSON info for a note splash skin.
**/
class SplashSkin extends JsonObject
{
	/**
		Loads a splash skin from a path to a JSON file.

		@return	A new `SplashSkin` object, or `null` if the path doesn't exist or if the JSON file couldn't be parsed.
	**/
	public static function loadSkin(path:String, ?mod:String):SplashSkin
	{
		if (!Paths.exists(path))
			return null;
			
		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;
			
		var skin = new SplashSkin(json);
		skin.directory = Path.normalize(Path.directory(path));
		skin.name = new Path(path).file;
		skin.mod = skin.directory.split('/')[1];
		return skin;
	}
	
	/**
		Loads a splash skin from a name.

		@param	name	The name of the skin to load. If it contains a colon `:`, it will use the name before it as
						the mod directory.
		@return	A new `SplashSkin` object, or `null` if the file couldn't be found or if the JSON file couldn't be
				parsed.
	**/
	public static function loadSkinFromName(name:String):SplashSkin
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = Paths.getPath('data/splashSkins/${nameInfo.name}.json', nameInfo.mod);
			if (Paths.exists(path))
				return loadSkin(path);
		}
		
		var path = Paths.getPath('data/splashSkins/$name.json');
		if (Paths.exists(path))
			return loadSkin(path);
			
		return loadSkin(Paths.getPath('data/splashSkins/$name.json', 'fnf'));
	}
	
	/**
		The list of splash configurations.
	**/
	public var splashes:Array<SplashData> = [];
	
	/**
		The name of the image for the splashes.
	**/
	public var image:String;
	
	/**
		If the image is a grid of sprites, this will indicate how wide each sprite is.
	**/
	public var tileWidth:Int;
	
	/**
		If the image is a grid of sprites, this will indicate how tall each sprite is.
	**/
	public var tileHeight:Int;
	
	/**
		The position offset for the splash positions.
	**/
	public var positionOffset:Array<Float>;
	
	/**
		The scaling factor for the splashes.
	**/
	public var scale:Float;
	
	/**
		Whether or not the splashes should have antialiasing
	**/
	public var antialiasing:Bool;
	
	/**
		The full directory path this splash skin was in.
	**/
	public var directory:String = '';
	
	/**
		The name of the splash skin.
	**/
	public var name:String = '';
	
	/**
		The mod directory this splash skin was in.
	**/
	public var mod:String = '';
	
	/**
		@param	data	The JSON file to parse data from.
	**/
	public function new(data:Dynamic)
	{
		for (s in readArray(data.splashes, null, null, 4))
		{
			if (s != null)
				splashes.push(new SplashData(s));
		}
		image = readString(data.image, 'splashes/noteSplashes');
		tileWidth = readInt(data.tileWidth, 0, 1);
		tileHeight = readInt(data.tileHeight, 0, 1);
		positionOffset = readFloatArray(data.positionOffset, [0, 0], null, 2, null, null, 2);
		scale = readFloat(data.scale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}
	
	override function destroy()
	{
		splashes = FlxDestroyUtil.destroyArray(splashes);
	}
}

/**
	JSON info for a splash.
**/
class SplashData extends JsonObject
{
	/**
		The name for the animation in the spritesheet.
	**/
	public var anim:String;
	
	/**
		Optional frame indices for the animation. If `anim` is empty, this will be used as indices in the overall
		spritesheet.
	**/
	public var indices:Array<Int>;
	
	/**
		The frame rate, or frames per second, for the animation.
	**/
	public var fps:Float;
	
	/**
		The visual offset for the animation.

		Values are substracted, so a value of `[5, -10]` will move the graphic 5 pixels left and 10 pixels down.
	**/
	public var offset:Array<Float>;
	
	public function new(data:Dynamic)
	{
		anim = readString(data.anim);
		indices = readIntArray(data.indices, [], null, null, 0);
		fps = readFloat(data.fps, 24, 0, 1000, 2);
		offset = readFloatArray(data.offset, [], null, 2, null, null, 2);
	}
	
	override function destroy()
	{
		offset = null;
	}
}
