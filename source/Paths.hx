package;

import data.Mods;
import data.PanLibrary;
import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.xml.Access;
import lime.app.Future;
import lime.app.Promise;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import util.MemoryUtil;
import util.StringUtil;

using StringTools;

/**
	A handy class for getting asset paths.
**/
class Paths
{
	/**
		Array of possible extensions for sound files.
	**/
	public static final SOUND_EXTENSIONS:Array<String> = [".ogg", ".wav"];
	
	/**
		Array of possible extensions for script files.
	**/
	public static final SCRIPT_EXTENSIONS:Array<String> = [".hx", ".hscript"];
	
	/**
		A map of currently cached sounds.
	**/
	public static var cachedSounds:Map<String, Sound> = [];
	
	/**
		List of sounds to exclude from dumping (removing from the cache).
	**/
	public static var dumpExclusions:Array<String> = [];
	
	/**
		The main library, which supports the `mods` folder.
	**/
	public static var library:PanLibrary;
	
	/**
		List of sounds currently in use.
	**/
	public static var trackedSounds:Array<String> = [];
	
	/**
		Excludes music from being dumped (removed from the cache).

		@param	path	The music path. Can be a full path or just the key inside `music/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
	**/
	public static function excludeMusic(path:String, ?mod:String)
	{
		if (exists(path))
			excludeAsset(path);
		else
			excludeSound(getPath('music/$path/audio'), mod);
	}
	
	/**
		Excludes a sound from being dumped (removed from the cache).

		@param	path	The sound path. Can be a full path or just the key inside `sounds/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
	**/
	public static function excludeSound(path:String, ?mod:String)
	{
		if (!StringUtil.endsWithAny(path, SOUND_EXTENSIONS))
			path += SOUND_EXTENSIONS[0];
			
		if (!exists(path))
			path = getPath('sounds/$path', mod);
			
		excludeAsset(path);
	}
	
	/**
		Returns whether or not a file path exists.
	**/
	public static function exists(path:String):Bool
	{
		return Assets.exists(path);
	}
	
	/**
		Returns whether or not a file path exists, using `getPath`.

		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
	**/
	public static function existsPath(key:String, ?mod:String):Bool
	{
		return exists(getPath(key, mod));
	}
	
	/**
		Gets the bytes content of a file.
	**/
	public static function getBytes(path:String):Bytes
	{
		if (exists(path))
			return Assets.getBytes(path);
		return null;
	}
	
	/**
		Gets the text content of a file.
	**/
	public static function getContent(path:String):String
	{
		if (exists(path))
			return Assets.getText(path).replace('\r', '').trim();
		return null;
	}
	
	/**
		Returns an image.

		@param	path	The image path. Can be a full path or just the key inside `images/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@param	cache	Whether or not to use the cache.
		@param	unique	Whether or not the returned graphic should be unique.
		@param	key		Optional key to use for the graphic. If unspecified, the path is used.
		@return An `FlxGraphic`, or `null` if it couldn't be found.
	**/
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
		
		if (!exists(path))
			return null;
			
		if (key == null)
			key = path;
			
		var graphic:FlxGraphic = FlxGraphic.fromAssetKey(path, unique, key, cache);
		if (graphic != null)
			graphic.destroyOnNoUse = false;
		return graphic;
	}
	
	/**
		Returns a JSON file.

		@param	path	The JSON path. Can be a full path or just the key inside `data/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	The JSON file, or `null` if it couldn't be found.
	**/
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
				CoolUtil.alert(e.message, "JSON Error");
			}
		}
		
		return null;
	}
	
	/**
		Returns music.

		@param	key		The music's name. Will add the extension if it's missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	A `Sound` object, or `null` if it couldn't be found.
	**/
	public static function getMusic(key:String, ?mod:String):Sound
	{
		return getSound('music/$key/audio', mod);
	}
	
	/**
		Gets a path to an asset using `key`.

		@param	mod	Optional mod directory to use. If unspecified, the current mod will be used.
	**/
	public static function getPath(key:String, ?mod:String):String
	{
		if (exists(key))
			return key;
			
		if (mod == null || mod.length == 0)
			mod = Mods.currentMod;
			
		var modPath = Path.join([Mods.modsPath, mod, key]);
		if (exists(modPath))
			return modPath;
			
		return 'assets/$key';
	}
	
	/**
		Gets the path to a script.

		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	The script path, or `null` if it couldn't be found.
	**/
	public static function getScriptPath(key:String, ?mod:String):String
	{
		for (ext in SCRIPT_EXTENSIONS)
		{
			var path = getPath(key + ext, mod);
			if (exists(path))
				return path;
		}
		
		return null;
	}
	
	/**
		Returns a song's instrumental. Takes the difficulty into account.
	**/
	public static function getSongInst(song:Song):Sound
	{
		if (song == null)
			return null;
			
		var diffSound = getSound(Path.join([song.directory, "Inst-" + song.difficultyName.toLowerCase()]), song.mod);
		if (diffSound != null)
			return diffSound;
		else
			return getSound(Path.join([song.directory, "Inst"]), song.mod);
	}
	
	/**
		Returns a song's vocals. Takes the difficulty into account.
	**/
	public static function getSongVocals(song:Song):Sound
	{
		if (song == null)
			return null;
			
		var diffSound = getSound(Path.join([song.directory, "Voices-" + song.difficultyName.toLowerCase()]), song.mod);
		if (diffSound != null)
			return diffSound;
		else
			return getSound(Path.join([song.directory, "Voices"]), song.mod);
	}
	
	/**
		Returns a sound.

		@param	path	The sound path. Can be a full path or just the key inside `sounds/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	A `Sound` object, or `null` if it couldn't be found.
	**/
	public static function getSound(path:String, ?mod:String):Sound
	{
		if (!StringUtil.endsWithAny(path, SOUND_EXTENSIONS))
			path += SOUND_EXTENSIONS[0];
			
		var ogPath = path;
		if (!exists(path))
			path = getPath(ogPath, mod);
		if (!exists(path))
			path = getPath('sounds/$ogPath', mod);
			
		var sound:Sound = null;
		if (cachedSounds.exists(path))
			sound = cachedSounds.get(path);
		else if (exists(path))
		{
			sound = Assets.getSound(path, false);
			if (sound != null)
				cachedSounds.set(path, sound);
		}
		
		if (sound != null && !trackedSounds.contains(path))
			trackedSounds.push(path);
			
		return sound;
	}
	
	/**
		Returns spritesheet frames.

		@param	path	The spritesheet path. Can be a full path or just the key inside `images/`. Will add the extension if
						it's missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@param	cache	Whether or not to use the cache for the graphic.
		@param	unique	Whether or not the graphic should be unique.
		@param	key		Optional key to use for the graphic. If unspecified, the path is used.
		@return	An `FlxAtlasFrames` object, or `null` if it couldn't be found.

	**/
	public static function getSpritesheet(path:String, ?mod:String, cache:Bool = true, unique:Bool = false, ?key:String):FlxAtlasFrames
	{
		var originalPath = path;
		
		var imagePath = path;
		if (!imagePath.endsWith('.png'))
			imagePath += '.png';
		if (!exists(imagePath))
			imagePath = getPath('images/$imagePath', mod);
		path = Path.withoutExtension(imagePath);
		
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
		
		Main.showNotification('Spritesheet \"$originalPath\" not found.', ERROR);
		return null;
	}
	
	/**
		Returns a text file.

		@param	path	The text path. Can be a full path or just the key inside `data/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	The text file, or `null` if it couldn't be found.
	**/
	public static function getText(path:String, ?mod:String):String
	{
		if (!path.endsWith('.txt'))
			path += '.txt';
		if (!exists(path))
			path = getPath('data/$path', mod);
			
		if (exists(path))
			return getContent(path);
			
		return null;
	}
	
	/**
		Gets the path to a video file.

		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
	**/
	public static function getVideo(path:String, ?mod:String):String
	{
		if (!path.endsWith('.mp4') && !path.endsWith('.webm'))
			path += '.mp4';
		if (!exists(path))
			path = getPath('videos/$path', mod);
		return path;
	}
	
	/**
		Returns an XML file.

		@param	path	The XML path. Can be a full path or just the key inside `data/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	The XML file, or `null` if it couldn't be found.
	**/
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
				CoolUtil.alert(e.message, "XML Error");
			}
		}
		
		return null;
	}
	
	/**
		Returns if the image is a spritesheet or not.

		@param	path	The image path. Can be a full path or just the key inside `images/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
	**/
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
	
	/**
		Initializes things.
	**/
	public static function init():Void
	{
		// use a modified library so we can get files in the mods folder
		library = new PanLibrary();
		lime.utils.Assets.registerLibrary("", library);
		
		excludeSound('menus/scrollMenu');
		excludeSound('menus/confirmMenu');
		excludeSound('menus/cancelMenu');
		excludeMusic("Gettin' Freaky");
		
		FlxG.signals.preStateSwitch.add(onPreStateSwitch);
		FlxG.signals.postStateSwitch.add(onPostStateSwitch);
	}
	
	/**
		Loads an image from a path.

		@param	path	The image path. Can be a full path or just the key inside `images/`. Will add the extension if it's
						missing.
		@param	mod		Optional mod directory to use. If unspecified, the current mod will be used.
		@return	A `Future` object containing the image, or `null` if it couldn't be found.
	**/
	public static function loadImage(path:String, ?mod:String):Future<FlxGraphic>
	{
		if (!path.endsWith('.png'))
			path += '.png';
		if (!exists(path))
			path = getPath('images/$path', mod);
		if (!exists(path))
			return Future.withValue(null);
			
		var promise = new Promise<FlxGraphic>();
		var future = BitmapData.loadFromFile(path);
		
		future.onProgress(promise.progress);
		future.onError(promise.error);
		future.onComplete(function(bitmap)
		{
			if (bitmap == null)
				return;
			var graphic = FlxG.bitmap.add(bitmap, false, path);
			graphic.destroyOnNoUse = false;
			promise.complete(graphic);
		});
		
		return promise.future;
	}
	
	static function excludeAsset(path:String)
	{
		if (!dumpExclusions.contains(path) && exists(path))
			dumpExclusions.push(path);
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
		
		// run garbage collector
		MemoryUtil.clearMajor();
	}
	
	static function onPreStateSwitch()
	{
		trackedSounds.resize(0);
		if (Settings.forceCacheReset || FlxG.keys.pressed.F5)
		{
			FlxG.bitmap.reset();
			for (k => s in cachedSounds)
			{
				cachedSounds.remove(k);
				if (s != null)
					s.close();
			}
		}
	}
}
