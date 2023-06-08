package data.skin;

import flixel.util.FlxDestroyUtil;
import haxe.io.Path;

/**
	Configuration for a note skin.
**/
class NoteSkin extends JsonObject
{
	public static function loadSkin(path:String, ?mod:String):NoteSkin
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;

		var skin = new NoteSkin(json);
		skin.directory = Path.normalize(Path.directory(path));
		skin.name = new Path(path).file;
		skin.mod = skin.directory.split('/')[1];
		return skin;
	}

	public static function loadSkinFromName(name:String):NoteSkin
	{
		var nameInfo = CoolUtil.getNameInfo(name);
		if (nameInfo.mod.length > 0)
		{
			var path = Paths.getPath('data/noteskins/${nameInfo.name}.json', nameInfo.mod);
			if (Paths.exists(path))
				return loadSkin(path);
		}

		var path = Paths.getPath('data/noteskins/$name.json');
		if (Paths.exists(path))
			return loadSkin(path);

		return loadSkin(Paths.getPath('data/noteskins/$name.json', 'fnf'));
	}

	/**
		The name of the image for the notes and receptors.
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
		The list of receptor configurations.
	**/
	public var receptors:Array<ReceptorData> = [];

	/**
		The offset for the receptors positions.
	**/
	public var receptorsOffset:Array<Float>;

	/**
		Extra horizontal padding for the receptors.
	**/
	public var receptorsPadding:Float;

	/**
		The scale for the receptors.
	**/
	public var receptorsScale:Float;

	/**
		Whether or not the receptors graphic is automatically centered when the pressed/confirm animation is played.
	**/
	public var receptorsCenterAnimation:Bool;

	/**
		The list of note configurations.
	**/
	public var notes:Array<NoteData> = [];

	/**
		The scale for the notes.
	**/
	public var notesScale:Float;

	/**
		Whether or not the sprites have antialiasing.
	**/
	public var antialiasing:Bool;

	public var directory:String = '';
	public var name:String = '';
	public var mod:String = '';

	public function new(data:Dynamic)
	{
		image = readString(data.image, 'notes/default');
		tileWidth = readInt(data.tileWidth, 17, 1);
		tileHeight = readInt(data.tileHeight, 17, 1);
		for (r in readArray(data.receptors, null, null, 4))
		{
			if (r != null)
				receptors.push(new ReceptorData(r));
		}
		receptorsCenterAnimation = readBool(data.receptorsCenterAnimation, true);
		receptorsOffset = readFloatArray(data.receptorsOffset, [0, 0], null, 2, -1000, 1000, 2);
		receptorsPadding = readFloat(data.receptorsPadding, 0, -1000, 1000, 2);
		receptorsScale = readFloat(data.receptorsScale, 1, 0.01, 100, 2);
		for (n in readArray(data.notes, null, null, 4))
		{
			if (n != null)
				notes.push(new NoteData(n));
		}
		notesScale = readFloat(data.notesScale, 1, 0.01, 100, 2);
		antialiasing = readBool(data.antialiasing, true);
	}

	override function destroy()
	{
		receptors = FlxDestroyUtil.destroyArray(receptors);
		receptorsOffset = null;
		notes = FlxDestroyUtil.destroyArray(notes);
	}
}

class ReceptorData extends JsonObject
{
	/**
		The name for the static animation in the spritesheet.
	**/
	public var staticAnim:String;

	/**
		The name for the pressed animation in the spritesheet.
	**/
	public var pressedAnim:String;

	/**
		The name for the confirm animation in the spritesheet.
	**/
	public var confirmAnim:String;

	public var staticIndices:Array<Int>;
	public var pressedIndices:Array<Int>;
	public var confirmIndices:Array<Int>;

	/**
		The FPS for the static animation.
	**/
	public var staticFPS:Float;

	/**
		The FPS for the pressed animation.
	**/
	public var pressedFPS:Float;

	/**
		The FPS for the confirm animation.
	**/
	public var confirmFPS:Float;

	/**
		The offset for the static animation. Overrides `receptorsCenterAnimation`.
	**/
	public var staticOffset:Array<Float>;

	/**
		The offset for the pressed animation. Overrides `receptorsCenterAnimation`.
	**/
	public var pressedOffset:Array<Float>;

	/**
		The offset for the confirm animation. Overrides `receptorsCenterAnimation`.
	**/
	public var confirmOffset:Array<Float>;

	public function new(data:Dynamic)
	{
		staticAnim = readString(data.staticAnim);
		pressedAnim = readString(data.pressedAnim);
		confirmAnim = readString(data.confirmAnim);
		staticIndices = readIntArray(data.staticIndices, [], null, null, 0);
		pressedIndices = readIntArray(data.pressedIndices, [], null, null, 0);
		confirmIndices = readIntArray(data.confirmIndices, [], null, null, 0);
		staticFPS = readFloat(data.staticFPS, 0, 0, 1000, 2);
		pressedFPS = readFloat(data.pressedFPS, 24, 0, 1000, 2);
		confirmFPS = readFloat(data.confirmFPS, 24, 0, 1000, 2);
		staticOffset = readFloatArray(data.staticOffset, [], null, 2, null, null, 2);
		pressedOffset = readFloatArray(data.pressedOffset, [], null, 2, null, null, 2);
		confirmOffset = readFloatArray(data.confirmOffset, [], null, 2, null, null, 2);
	}

	override function destroy()
	{
		staticIndices = null;
		pressedIndices = null;
		confirmIndices = null;
		staticOffset = null;
		pressedOffset = null;
		confirmOffset = null;
	}
}

class NoteData extends JsonObject
{
	public var headAnim:String;
	public var bodyAnim:String;
	public var tailAnim:String;
	public var headIndices:Array<Int>;
	public var bodyIndices:Array<Int>;
	public var tailIndices:Array<Int>;

	public function new(data:Dynamic)
	{
		headAnim = readString(data.headAnim);
		bodyAnim = readString(data.bodyAnim);
		tailAnim = readString(data.tailAnim);
		headIndices = readIntArray(data.headIndices, [], null, null, 0);
		bodyIndices = readIntArray(data.bodyIndices, [], null, null, 0);
		tailIndices = readIntArray(data.tailIndices, [], null, null, 0);
	}

	override function destroy()
	{
		headIndices = null;
		bodyIndices = null;
		tailIndices = null;
	}
}
