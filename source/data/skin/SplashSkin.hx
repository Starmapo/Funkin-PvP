package data.skin;

import flixel.util.FlxDestroyUtil;
import haxe.io.Path;

class SplashSkin extends JsonObject
{
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

	public var splashes:Array<SplashData> = [];
	public var image:String;
	public var scale:Float;
	public var antialiasing:Bool;
	public var directory:String = '';
	public var name:String = '';
	public var mod:String = '';

	public function new(data:Dynamic)
	{
		for (s in readArray(data.splashes, null, null, 4))
		{
			if (s != null)
				splashes.push(new SplashData(s));
		}
		image = readString(data.image, 'splashes/noteSplashes');
		scale = readFloat(data.scale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}

	override function destroy()
	{
		splashes = FlxDestroyUtil.destroyArray(splashes);
	}
}

class SplashData extends JsonObject
{
	public var anim:String;
	public var fps:Float;
	public var offset:Array<Float>;

	public function new(data:Dynamic)
	{
		anim = readString(data.anim);
		fps = readFloat(data.fps, 24, 0, 1000, 2);
		offset = readFloatArray(data.offset, [], null, 2, null, null, 2);
	}

	override function destroy()
	{
		offset = null;
	}
}
