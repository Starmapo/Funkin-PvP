package data;

import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.Bytes;
import sys.FileSystem;

using StringTools;

// it goes both ways?
// i couldn't think of a better name, sorry
class BiLibrary extends AssetLibrary
{
	final rootPath = './';

	override function exists(id:String, type:String)
	{
		return FileSystem.exists(getSysPath(id));
	}

	override function getAudioBuffer(id:String)
	{
		return AudioBuffer.fromFile(getSysPath(id));
	}

	override function getBytes(id:String)
	{
		return Bytes.fromFile(getSysPath(id));
	}

	override function getFont(id:String)
	{
		return Font.fromFile(getSysPath(id));
	}

	override function getImage(id:String)
	{
		return Image.fromFile(getSysPath(id));
	}

	override function getText(id:String):String
	{
		var bytes = getBytes(id);

		if (bytes == null)
			return null;
		else
			return bytes.getString(0, bytes.length);
	}

	override function list(type:String)
	{
		var items:Array<String> = [];

		function pushFolder(path:String)
		{
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
			{
				for (file in FileSystem.readDirectory(path))
				{
					var full = Path.join([path, file]);
					if (FileSystem.isDirectory(full))
						pushFolder(path);
					else
						items.push(Path.normalize(full));
				}
			}
		}

		pushFolder('assets/');
		pushFolder('mods/');

		return items;
	}

	function getSysPath(id:String)
	{
		return rootPath + id;
	}
}
