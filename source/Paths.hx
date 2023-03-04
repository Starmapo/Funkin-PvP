import data.song.Song;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import haxe.io.Path;
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
	public static var currentMod:String = 'fnf';

	/**
		Cache of sounds that have been loaded.
	**/
	public static var cachedSounds:Map<String, Sound> = new Map();

	public static function getPath(key:String, ?mod:String):String
	{
		if (mod == null)
			mod = currentMod;

		var modPath = 'mods/$mod/$key';
		if (exists(modPath))
			return modPath;

		return 'assets/$key';
	}

	public static function getImage(path:String, ?mod:String):FlxGraphic
	{
		var originalPath = path;

		if (!path.endsWith('.png'))
			path += '.png';

		if (!exists(path))
			path = getPath('images/$path', mod);

		if (FlxG.bitmap.checkCache(path))
			return FlxG.bitmap.get(path);

		// exists in openfl assets, so get it from there
		if (Assets.exists(path, IMAGE))
		{
			return FlxGraphic.fromAssetKey(path, false, path);
		}
		#if sys
		// otherwise, get it from the file
		else if (FileSystem.exists(path))
		{
			var bitmap = BitmapData.fromFile(path);
			return FlxGraphic.fromBitmapData(bitmap, false, path);
		}
		#end

		FlxG.log.warn('Graphic \"$originalPath\" not found.');
		return null;
	}

	public static function getSpritesheet(path:String, ?mod:String):FlxAtlasFrames
	{
		var originalPath = path;

		var imagePath = path + '.png';
		if (!exists(imagePath))
		{
			imagePath = getPath('images/$imagePath');
			path = Path.withoutExtension(imagePath);
		}

		var image = getImage(imagePath, mod);
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

	public static function getSound(path:String, ?mod:String):Sound
	{
		var originalPath = path;

		if (!path.endsWith('.ogg') && !path.endsWith('.mp3') && !path.endsWith('.wav'))
			path += '.ogg';

		if (!exists(path))
			path = getPath('sounds/$path', mod);

		if (cachedSounds.exists(path))
			return cachedSounds.get(path);

		if (Assets.exists(path, SOUND))
		{
			var sound = Assets.getSound(path);
			cachedSounds.set(path, sound);
			return sound;
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			var sound = Sound.fromFile('./$path');
			cachedSounds.set(path, sound);
			return sound;
		}
		#end

		FlxG.log.warn('Sound \"$originalPath\" not found.');
		return null;
	}

	public static function getMusic(path:String, ?mod:String)
	{
		return getSound(getPath('music/$path/audio'), mod);
	}

	public static function getSongInst(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/${song.instFile}', mod);
	}

	public static function getSongVocals(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/${song.vocalsFile}', mod);
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

	public static function getJson(path:String, ?mod:String)
	{
		if (!path.endsWith('.json'))
			path += '.json';
		if (!exists(path))
			path = getPath('data/$path', mod);

		if (exists(path))
			return Json.parse(getContent(path));

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
		// idk if this does anything but whatever
		for (_ => sound in cachedSounds)
		{
			sound.close();
		}
		cachedSounds.clear();
	}
}
