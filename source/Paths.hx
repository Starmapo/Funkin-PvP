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
import openfl.display3D.utils.UInt8Buff;
import openfl.media.Sound;
import openfl.utils.AssetCache;
import util.MemoryUtil;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	public static var SCRIPT_EXTENSIONS:Array<String> = [".hx", ".hscript"];

	public static var cachedSounds:Map<String, Sound> = [];
	public static var trackedSounds:Array<String> = [];
	public static var dumpExclusions:Array<String> = [];

	public static function init()
	{
		excludeSound('menus/scrollMenu');
		excludeSound('menus/confirmMenu');
		excludeSound('menus/cancelMenu');
		excludeMusic("Gettin' Freaky");

		FlxG.signals.preStateSwitch.add(onPreStateSwitch);
		FlxG.signals.postStateSwitch.add(onPostStateSwitch);
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
		if (!path.endsWith('.png'))
			path += '.png';

		if (!exists(path))
			path = getPath('images/$path', mod);

		if (cache && !unique)
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
			@:privateAccess
			graphic.assetsKey = path;
		}
		#end

		/* if (graphic == null)
			trace('Graphic \"$originalPath\" not found.'); */

		return graphic;
	}

	public static function getSpritesheet(path:String, ?mod:String, cache:Bool = true, unique:Bool = false, ?key:String):FlxAtlasFrames
	{
		var originalPath = path;

		var imagePath = path;
		if (!imagePath.endsWith('.png'))
			imagePath += '.png';
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
		var imagePath = path;
		if (!imagePath.endsWith('.png'))
			imagePath += '.png';
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
		if (!path.endsWith('.ogg') && !path.endsWith('.wav'))
			path += '.ogg';

		if (!exists(path))
			path = getPath('sounds/$path', mod);

		var sound:Sound = null;
		if (cachedSounds.exists(path))
			sound = cachedSounds.get(path);
		else if (Assets.exists(path, SOUND))
		{
			sound = Assets.getSound(path, false);
			if (sound != null)
				cachedSounds.set(path, sound);
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			sound = Sound.fromFile('./$path');
			if (sound != null)
				cachedSounds.set(path, sound);
		}
		#end

		if (sound != null && !trackedSounds.contains(path))
			trackedSounds.push(path);

		return sound;
	}

	public static function getMusic(path:String, ?mod:String)
	{
		if (exists(path))
			return getSound(path, mod);

		return getSound(getPath('music/$path/audio.ogg'), mod);
	}

	public static function getSongInst(song:Song)
	{
		return getSound('${song.directory}/Inst.ogg', song.mod);
	}

	public static function getSongVocals(song:Song)
	{
		return getSound('${song.directory}/Voices.ogg', song.mod);
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

	public static function getXml(path:String, ?mod:String):Xml
	{
		if (!path.endsWith('.xml'))
			path += '.xml';
		if (!exists(path))
			path = getPath('data/$path', mod);

		if (exists(path))
		{
			try
			{
				var xml = Xml.parse(getContent(path));
				return xml;
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
			return Assets.getText(path).replace('\r', '').trim();
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			return File.getContent(path).replace('\r', '').trim();
		}
		#end
		return null;
	}

	public static function getVideo(path:String, ?mod:String)
	{
		if (!path.endsWith('.mp4') && !path.endsWith('.webm'))
			path += '.mp4';
		return getPath('videos/$path', mod);
	}

	public static function exists(path:String):Bool
	{
		return Assets.exists(path) #if sys || FileSystem.exists(path) #end;
	}

	public static function existsPath(key:String, ?mod:String):Bool
	{
		return exists(getPath(key, mod));
	}

	public static function excludeAsset(path:String)
	{
		if (!dumpExclusions.contains(path) && exists(path))
			dumpExclusions.push(path);
	}

	public static function excludeSound(path:String, ?mod:String)
	{
		if (!path.endsWith('.ogg') && !path.endsWith('.wav'))
			path += '.ogg';

		if (!exists(path))
			path = getPath('sounds/$path', mod);

		excludeAsset(path);
	}

	public static function excludeMusic(path:String, ?mod:String)
	{
		if (exists(path))
			return excludeAsset(path);

		return excludeSound(getPath('music/$path/audio.ogg'), mod);
	}

	static function onPreStateSwitch()
	{
		trackedSounds.resize(0);
		if (Settings.forceCacheReset || FlxG.keys.pressed.SHIFT)
		{
			@:privateAccess
			{
				for (k => _ in FlxG.bitmap._cache)
					FlxG.bitmap.removeByKey(k);
				FlxG.bitmap._cache.clear();
				FlxG.bitmap.__countCache.resize(0);
				FlxG.bitmap.__cacheCopy.clear();
			}
			for (k => s in cachedSounds)
			{
				cachedSounds.remove(k);
				if (s != null)
					s.close();
			}
		}
	}

	static function onPostStateSwitch()
	{
		// Remove all unused sounds from the cache.
		// Makes sure sounds that are currently playing don't get removed, like music or persistent sounds
		var playingSounds:Array<Sound> = [];
		@:privateAccess {
			if (FlxG.sound.music != null && FlxG.sound.music._sound != null && !playingSounds.contains(FlxG.sound.music._sound))
				playingSounds.push(FlxG.sound.music._sound);
			for (sound in FlxG.sound.list)
			{
				if (sound != null && sound._sound != null && !playingSounds.contains(sound._sound))
					playingSounds.push(sound._sound);
			}
		}
		for (k => s in cachedSounds)
		{
			if (s != null && !trackedSounds.contains(k) && !dumpExclusions.contains(k) && !playingSounds.contains(s))
			{
				cachedSounds.remove(k);
				s.close();
			}
		}

		@:privateAccess {
			// clear uint8 pools
			for (_ => pool in UInt8Buff._pools)
			{
				for (b in pool.clear())
					b.destroy();
			}
			UInt8Buff._pools.clear();
		}

		// run garbage collector
		MemoryUtil.clearMajor();
	}
}
