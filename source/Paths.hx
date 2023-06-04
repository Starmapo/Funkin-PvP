import data.Mods;
import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import haxe.io.Path;
import haxe.xml.Access;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	public static var SCRIPT_EXTENSIONS:Array<String> = [".hx", ".hscript"];

	public static var cachedSounds:Map<String, Sound> = new Map();
	public static var trackingAssets:Bool = false;
	public static var trackedGraphics:Array<FlxGraphic> = [];
	public static var trackedSounds:Array<String> = [];

	public static function init()
	{
		FlxG.signals.preStateSwitch.add(function()
		{
			if (!Settings.persistentCache || FlxG.keys.pressed.F5)
				clear();
		});
	}

	public static function getPath(key:String, ?mod:String):String
	{
		if (mod == null || mod.length == 0)
			mod = Mods.currentMod;

		var modPath = '${Mods.modsPath}/$mod/$key';
		if (exists(modPath))
			return modPath;

		return 'assets/$key';
	}

	public static function getImage(path:String, ?mod:String, cache:Bool = true, unique:Bool = false, ?key:String):FlxGraphic
	{
		var originalPath = path;

		if (!path.endsWith('.png'))
			path += '.png';

		if (!exists(path))
			path = getPath('images/$path', mod);

		if (!cache && !unique)
		{
			if (key != null && FlxG.bitmap.checkCache(key))
				return FlxG.bitmap.get(key);
			if (FlxG.bitmap.checkCache(path))
				return FlxG.bitmap.get(path);
		}

		if (key == null)
			key = path;

		var graphic:FlxGraphic = null;
		// exists in openfl assets, so get it from there
		if (Assets.exists(path, IMAGE))
			graphic = FlxGraphic.fromAssetKey(path, unique, key, cache);
		#if sys
		// otherwise, get it from the file
		else if (FileSystem.exists(path))
		{
			var bitmap = BitmapData.fromFile(path);
			graphic = FlxGraphic.fromBitmapData(bitmap, unique, key, cache);
		}
		#end

		if (graphic == null)
			trace('Graphic \"$originalPath\" not found.');
		else if (trackingAssets && !trackedGraphics.contains(graphic))
			trackedGraphics.push(graphic);

		return graphic;
	}

	public static function getSpritesheet(path:String, ?mod:String, cache:Bool = true, unique:Bool = false, ?key:String):FlxAtlasFrames
	{
		var originalPath = path;

		var imagePath = path + '.png';
		if (!exists(imagePath))
		{
			imagePath = getPath('images/$imagePath', mod);
			path = Path.withoutExtension(imagePath);
		}

		var image = getImage(imagePath, mod, cache, unique, key);
		if (image == null)
			return null;

		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(image);
		if (frames != null)
			return frames;

		var description:String = getContent('$path.xml');
		if (description != null)
		{
			frames = FlxAtlasFrames.fromSparrow(image, description);
			if (frames != null)
				return frames;
		}

		description = getContent('$path.txt');
		if (description != null)
		{
			frames = FlxAtlasFrames.fromSpriteSheetPacker(image, description);
			if (frames != null)
				return frames;
		}

		description = getContent('$path.json');
		if (description != null)
		{
			frames = FlxAtlasFrames.fromTexturePackerJson(image, description);
			if (frames != null)
				return frames;
		}

		FlxG.log.warn('Spritesheet \"$originalPath\" not found.');
		return null;
	}

	public static function isSpritesheet(path:String, ?mod:String):Bool
	{
		var imagePath = path + '.png';
		if (!exists(imagePath))
		{
			imagePath = getPath('images/$imagePath', mod);
			path = Path.withoutExtension(imagePath);
		}
		if (!exists(imagePath))
			return false;

		var xml = getContent('$path.xml');
		if (xml != null)
		{
			try
			{
				var data = new Access(Xml.parse(xml).firstElement());
				if (data.hasNode.SubTexture)
					return true;
			}
			catch (e) {}
		}

		var txt = getContent('$path.txt');
		if (txt != null)
		{
			var lines = txt.trim().split('\n');
			if (lines.length > 0 && lines[0].contains('='))
				return true;
		}

		var json = getContent('$path.json');
		if (json != null)
		{
			try
			{
				var data = Json.parse(json);
				if (data != null && data.frames != null)
					return true;
			}
			catch (e) {}
		}

		return false;
	}

	public static function getSound(path:String, ?mod:String):Sound
	{
		if (!path.endsWith('.ogg') && !path.endsWith('.mp3') && !path.endsWith('.wav'))
			path += '.ogg';

		if (!exists(path))
			path = getPath('sounds/$path', mod);

		if (cachedSounds.exists(path))
			return cachedSounds.get(path);

		var sound:Sound = null;
		if (Assets.exists(path, SOUND))
			sound = Assets.getSound(path, false);
		#if sys
		else if (FileSystem.exists(path))
			sound = Sound.fromFile('./$path');
		#end

		if (sound != null)
		{
			cachedSounds.set(path, sound);
			if (trackingAssets && !trackedSounds.contains(path))
				trackedSounds.push(path);
		}

		return sound;
	}

	public static function getMusic(path:String, ?mod:String)
	{
		if (exists(path))
			return getSound(path, mod);

		return getSound(getPath('music/$path/audio'), mod);
	}

	public static function getSongInst(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/Inst.ogg', mod);
	}

	public static function getSongVocals(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/Voices.ogg', mod);
	}

	public static function getText(path:String, ?mod:String)
	{
		if (!path.endsWith('.txt'))
			path += '.txt';
		if (!exists(path))
			path = getPath('data/$path', mod);

		if (exists(path))
			return getContent(path);

		return null;
	}

	public static function getJson(path:String, ?mod:String):Dynamic
	{
		if (!path.endsWith('.json'))
			path += '.json';
		if (!exists(path))
			path = getPath('data/$path', mod);

		if (exists(path))
		{
			try
			{
				var json = Json.parse(getContent(path));
				return json;
			}
			catch (e)
			{
				trace(e);
			}
		}

		return null;
	}

	public static function getScriptPath(key:String, ?mod:String)
	{
		for (ext in SCRIPT_EXTENSIONS)
		{
			var path = getPath(key + ext, mod);
			if (exists(path))
				return path;
		}

		return null;
	}

	public static function getContent(path:String)
	{
		if (Assets.exists(path))
		{
			return Assets.getText(path).trim();
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			return File.getContent(path).trim();
		}
		#end
		return null;
	}

	public static function exists(path:String):Bool
	{
		return Assets.exists(path) #if sys || FileSystem.exists(path) #end;
	}

	public static function existsPath(key:String, ?mod:String):Bool
	{
		return exists(getPath(key, mod));
	}

	public static function clear()
	{
		clearImages();
		clearSounds();
		Assets.cache.clear('');
	}

	public static function clearImages()
	{
		FlxG.bitmap.reset();
	}

	public static function clearSounds()
	{
		cachedSounds.clear();
	}

	public static function clearTrackedAssets()
	{
		trace('Removing ${trackedGraphics.length} graphic' + (trackedGraphics.length != 1 ? 's' : ''));
		for (graphic in trackedGraphics)
			FlxG.bitmap.remove(graphic);
		trackedGraphics.resize(0);

		trace('Removing ${trackedSounds.length} sound' + (trackedSounds.length != 1 ? 's' : ''));
		for (key in trackedSounds)
			cachedSounds.remove(key);
		trackedSounds.resize(0);
	}
}
