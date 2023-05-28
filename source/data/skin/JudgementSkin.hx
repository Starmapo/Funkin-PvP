package data.skin;

import haxe.io.Path;

class JudgementSkin extends JsonObject
{
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

	public var scale:Float;
	public var antialiasing:Bool;
	public var directory:String = '';
	public var name:String = '';
	public var mod:String = '';

	public function new(data:Dynamic)
	{
		scale = readFloat(data.scale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}
}
