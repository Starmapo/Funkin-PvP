import data.song.Song;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
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

		var graphic:FlxGraphic = null;

		// exists in openfl assets, so get it from there
		if (Assets.exists(path, IMAGE))
		{
			graphic = FlxGraphic.fromAssetKey(path);
		}
		#if sys
		// otherwise, get it from the file
		else if (FileSystem.exists(path))
		{
			var bitmap = BitmapData.fromFile(path);
			graphic = FlxGraphic.fromBitmapData(bitmap);
		}
		#end

		if (graphic == null)
			FlxG.log.warn('Graphic \"$originalPath\" not found.');

		return graphic;
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

		if (Assets.exists(path, SOUND))
		{
			return Assets.getSound(path);
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			return Sound.fromFile(path);
		}
		#end

		FlxG.log.warn('Sound \"$originalPath\" not found.');
		return null;
	}

	public static function getSongInst(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/${song.instFile}', mod);
	}

	public static function getSongVocals(song:Song, ?mod:String)
	{
		return getSound('${song.directory}/${song.vocalsFile}', mod);
	}

	public static function getContent(path:String)
	{
		if (Assets.exists(path))
		{
			return Assets.getText(path);
		}
		#if sys
		else if (FileSystem.exists(path))
		{
			return File.getContent(path);
		}
		#end
		return null;
	}

	public static function exists(path:String):Bool
	{
		return Assets.exists(path) #if sys || FileSystem.exists(path) #end;
	}
}
