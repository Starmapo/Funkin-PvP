package backend.assets;

import backend.structures.song.Song;
import backend.util.MemoryUtil;
import backend.util.StringUtil;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.xml.Access;
import openfl.Assets;
import openfl.media.Sound;

using StringTools;

/**
	A handy class for getting asset paths.
**/
class Paths
{
	public static final FONT_PHANTOMMUFF:String = "PhantomMuff 1.5";
	
	public static final FONT_PIXEL:String = "Pixel Arial 11 Bold";
	
	public static final FONT_VCR:String = "VCR OSD Mono";
	
	public static final SOUND_EXTENSIONS:Array<String> = [".ogg", ".wav"];
	
	public static final SCRIPT_EXTENSIONS:Array<String> = [".hx", ".hscript"];
	
	public static var clearCache:Bool = false;
	
	public static var currentTrackedGraphics:Map<String, FlxGraphic> = new Map();
	
	public static var currentTrackedSounds:Map<String, Sound> = new Map();
	
	public static var dumpExclusions:Array<String> = [];
	
	public static var library:PanLibrary;
	
	public static var localTrackedAssets:Array<String> = [];
	
	public static function excludeMusic(path:String, ?mod:String)
	{
		if (exists(path))
			excludeAsset(path);
		else
			excludeSound(getPath('music/$path/audio'), mod);
	}
	
	public static function excludeSound(path:String, ?mod:String)
	{
		if (!StringUtil.endsWithAny(path, SOUND_EXTENSIONS))
			path += SOUND_EXTENSIONS[0];
			
		if (!exists(path))
			path = getPath('sounds/$path', mod);
			
		excludeAsset(path);
	}
	
	public static function exists(path:String):Bool
	{
		return Assets.exists(path);
	}
	
	public static function existsPath(key:String, ?mod:String):Bool
	{
		return exists(getPath(key, mod));
	}
	
	public static function getBytes(path:String):Bytes
	{
		if (exists(path))
			return Assets.getBytes(path);
		return null;
	}
	
	public static function getContent(path:String):String
	{
		if (exists(path))
			return Assets.getText(path).replace('\r', '').trim();
		return null;
	}
	
	public static function getImage(path:String, ?mod:String, ?key:String):FlxGraphic
	{
		if (!path.endsWith('.png'))
			path += '.png';
			
		if (!exists(path))
			path = getPath('images/$path', mod);
			
		if (key == null)
			key = path;
			
		if (currentTrackedGraphics.exists(key))
		{
			pushTrackedAsset(key);
			return currentTrackedGraphics.get(key);
		}
		
		if (!exists(path))
			return null;
			
		var graphic:FlxGraphic = FlxGraphic.fromAssetKey(path, false, key);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		
		pushTrackedAsset(key);
		currentTrackedGraphics.set(key, graphic);
		return graphic;
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
				CoolUtil.alert(e.message, "JSON Error");
			}
		}
		
		return null;
	}
	
	public static function getMusic(key:String, ?mod:String):Sound
	{
		return getSound('music/$key/audio', mod);
	}
	
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
	
	public static function getSound(path:String, ?mod:String):Sound
	{
		if (!StringUtil.endsWithAny(path, SOUND_EXTENSIONS))
			path += SOUND_EXTENSIONS[0];
			
		var ogPath = path;
		if (!exists(path))
			path = getPath(ogPath, mod);
		if (!exists(path))
			path = getPath('sounds/$ogPath', mod);
			
		if (currentTrackedSounds.exists(path))
		{
			pushTrackedAsset(path);
			return currentTrackedSounds.get(path);
		}
		
		var sound:Sound = Assets.getSound(path, false);
		if (sound != null)
		{
			pushTrackedAsset(path);
			currentTrackedSounds.set(path, sound);
		}
		return sound;
	}
	
	public static function getSpritesheet(path:String, ?mod:String):FlxAtlasFrames
	{
		var originalPath = path;
		
		var imagePath = path;
		if (!imagePath.endsWith('.png'))
			imagePath += '.png';
		if (!exists(imagePath))
			imagePath = getPath('images/$imagePath', mod);
		path = Path.withoutExtension(imagePath);
		
		var image = getImage(imagePath, mod);
		if (image == null)
			return null;
			
		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(image);
		if (frames != null)
			return frames;
			
		var description:String = getContent('$path.xml');
		if (description != null)
		{
			frames = FNFAtlasFrames.fromSparrow(image, description);
			if (frames != null)
				return frames;
		}
		
		description = getContent('$path.txt');
		if (description != null)
		{
			frames = FNFAtlasFrames.fromSpriteSheetPacker(image, description);
			if (frames != null)
				return frames;
		}
		
		description = getContent('$path.json');
		if (description != null)
		{
			frames = FNFAtlasFrames.fromTexturePackerJson(image, description);
			if (frames != null)
				return frames;
		}
		
		return null;
	}
	
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
	
	public static function getVideo(path:String, ?mod:String):String
	{
		if (!path.endsWith('.mp4') && !path.endsWith('.webm'))
			path += '.mp4';
		if (!exists(path))
			path = getPath('videos/$path', mod);
		return path;
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
				CoolUtil.alert(e.message, "XML Error");
			}
		}
		
		return null;
	}
	
	public static function isDirectory(path:String):Bool
	{
		return library.isDirectory(path);
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
	
	public static function init():Void
	{
		// use a modified library so we can get files in the mods folder
		library = new PanLibrary();
		lime.utils.Assets.registerLibrary("", library);
		
		excludeMusic("Gettin' Freaky");
		
		FlxG.signals.preStateSwitch.add(onPreStateSwitch);
		FlxG.signals.postStateSwitch.add(onPostStateSwitch);
	}
	
	public static function readDirectory(path:String):Array<String>
	{
		return library.readDirectory(path);
	}
	
	static function excludeAsset(path:String)
	{
		if (!dumpExclusions.contains(path) && exists(path))
			dumpExclusions.push(path);
	}
	
	static function onPostStateSwitch()
	{
		if (clearCache || Settings.forceCacheReset)
		{
			for (key in currentTrackedGraphics.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
				{
					var obj = currentTrackedGraphics.get(key);
					@:privateAccess
					if (obj != null)
					{
						currentTrackedGraphics.remove(key);
						
						obj.persist = false;
						obj.destroyOnNoUse = true;
						FlxG.bitmap.remove(obj);
					}
				}
			}
			
			clearCache = false;
		}
		
		// run garbage collector
		MemoryUtil.clearMajor();
	}
	
	static function onPreStateSwitch()
	{
		if (clearCache || Settings.forceCacheReset)
		{
			for (key in currentTrackedSounds.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
					currentTrackedSounds.remove(key);
			}
			
			localTrackedAssets.resize(0);
		}
	}
	
	static function pushTrackedAsset(path:String)
	{
		if (!localTrackedAssets.contains(path))
			localTrackedAssets.push(path);
	}
}
