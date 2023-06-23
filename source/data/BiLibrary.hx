package data;

import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.AssetType;
import lime.utils.Assets;
import lime.utils.Bytes;
import sys.FileSystem;

using StringTools;

class BiLibrary extends AssetLibrary
{
	final rootPath = './';

	var defaultLibrary:AssetLibrary;

	public function new(?defaultLibrary:AssetLibrary)
	{
		super();
		if (defaultLibrary == null)
			defaultLibrary = Assets.getLibrary("default");
		this.defaultLibrary = defaultLibrary;
	}

	/**
		`type` isn't supported for FileSystem checks!
	**/
	override function exists(id:String, type:String):Bool
	{
		if (defaultLibrary.exists(id, type))
			return true;
		return FileSystem.exists(getSysPath(id));
	}

	override function getAudioBuffer(id:String):AudioBuffer
	{
		if (defaultLibrary.exists(id, AssetType.SOUND))
			return defaultLibrary.getAudioBuffer(id);
		else
			return AudioBuffer.fromFile(getSysPath(id));
	}

	override function getBytes(id:String):Bytes
	{
		if (defaultLibrary.exists(id, AssetType.BINARY))
			return defaultLibrary.getBytes(id);
		else
			return Bytes.fromFile(getSysPath(id));
	}

	override function getFont(id:String):Font
	{
		if (defaultLibrary.exists(id, AssetType.FONT))
			return defaultLibrary.getFont(id);
		else
			return Font.fromFile(getSysPath(id));
	}

	override function getImage(id:String):Image
	{
		if (defaultLibrary.exists(id, AssetType.IMAGE))
			return defaultLibrary.getImage(id);
		else
			return Image.fromFile(getSysPath(id));
	}

	override function getText(id:String):String
	{
		if (defaultLibrary.exists(id, AssetType.TEXT))
			return defaultLibrary.getText(id);
		else
		{
			var bytes = getBytes(id);

			if (bytes == null)
				return null;
			else
				return bytes.getString(0, bytes.length);
		}
	}

	/**
		`type` isn't supported for FileSystem checks!
	**/
	override function list(type:String):Array<String>
	{
		var items:Array<String> = defaultLibrary.list(type);

		function pushFolder(path:String)
		{
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
			{
				for (file in FileSystem.readDirectory(path))
				{
					var full = Path.join([path, file]);
					if (FileSystem.isDirectory(full))
						pushFolder(path);
					else if (!items.contains(full))
						items.push(full);
				}
			}
		}

		pushFolder('mods/');

		return items;
	}

	function getSysPath(id:String):String
	{
		return rootPath + id;
	}
}
