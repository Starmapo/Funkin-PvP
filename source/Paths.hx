import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.Assets;
import openfl.display.BitmapData;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	public static function getPath(key:String):String
	{
		return 'assets/$key';
	}

	public static function getImage(key:String):FlxGraphic
	{
		var graphic:FlxGraphic = null;
		var path = getPath('images/$key.png');

		// exists in openfl assets, so get it from there
		if (Assets.exists(path))
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
			FlxG.log.warn('Graphic \"$key\" not found.');

		return graphic;
	}

	public static function getSpritesheet(key:String):FlxAtlasFrames
	{
		var image = getImage(key);
		if (image == null)
			return null;

		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(image);
		if (frames != null)
			return frames;

		var description:String = getContent(getPath('images/$key.xml'));
		if (description != null)
		{
			frames = FlxAtlasFrames.fromSparrow(image, description);
			if (frames != null)
				return frames;
		}

		description = getContent(getPath('images/$key.txt'));
		if (description != null)
		{
			frames = FlxAtlasFrames.fromSpriteSheetPacker(image, description);
			if (frames != null)
				return frames;
		}

		description = getContent(getPath('images/$key.json'));
		if (description != null)
		{
			frames = FlxAtlasFrames.fromTexturePackerJson(image, description);
			if (frames != null)
				return frames;
		}

		FlxG.log.warn('Spritesheet \"$key\" not found.');
		return null;
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
