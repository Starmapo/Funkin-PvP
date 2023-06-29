package data;

import haxe.io.Path;
import haxe.zip.Entry;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.AssetType;
import lime.utils.Assets;
import lime.utils.Bytes;
import sys.FileSystem;
import util.Zip;

using StringTools;

class BiLibrary extends AssetLibrary
{
	final rootPath = './';

	var defaultLibrary:AssetLibrary;
	var zipAssets:Map<String, Entry> = [];

	public function new(?defaultLibrary:AssetLibrary)
	{
		super();
		if (defaultLibrary == null)
			defaultLibrary = Assets.getLibrary("default");
		this.defaultLibrary = defaultLibrary;
	}

	public function addZipMod(list:List<Entry>, modPath:String)
	{
		if (list == null)
			return;
		if (!modPath.endsWith('/'))
			modPath += '/';
		for (entry in list)
		{
			var name = entry.fileName;
			if (Path.extension(name).length < 1)
				continue;
			zipAssets.set(modPath + name, entry);
			trace(modPath + name);
		}
	}

	public function clearZipMods()
	{
		zipAssets.clear();
	}

	/**
		`type` isn't supported for FileSystem checks!
	**/
	override function exists(id:String, type:String):Bool
	{
		if (defaultLibrary.exists(id, type) || zipAssets.exists(id))
			return true;
		return FileSystem.exists(getSysPath(id));
	}

	override function getAudioBuffer(id:String):AudioBuffer
	{
		if (defaultLibrary.exists(id, AssetType.SOUND))
			return defaultLibrary.getAudioBuffer(id);
		else if (zipAssets.exists(id))
			return AudioBuffer.fromBytes(getZipData(id));
		else
			return AudioBuffer.fromFile(getSysPath(id));
	}

	override function getBytes(id:String):Bytes
	{
		if (defaultLibrary.exists(id, AssetType.BINARY))
			return defaultLibrary.getBytes(id);
		else if (zipAssets.exists(id))
			return getZipData(id);
		else
			return Bytes.fromFile(getSysPath(id));
	}

	override function getFont(id:String):Font
	{
		if (defaultLibrary.exists(id, AssetType.FONT))
			return defaultLibrary.getFont(id);
		else if (zipAssets.exists(id))
			return Font.fromBytes(getZipData(id));
		else
			return Font.fromFile(getSysPath(id));
	}

	override function getImage(id:String):Image
	{
		if (defaultLibrary.exists(id, AssetType.IMAGE))
			return defaultLibrary.getImage(id);
		else if (zipAssets.exists(id))
			return Image.fromBytes(getZipData(id));
		else
			return Image.fromFile(getSysPath(id));
	}

	override function getText(id:String):String
	{
		if (defaultLibrary.exists(id, AssetType.TEXT))
			return defaultLibrary.getText(id);
		else if (zipAssets.exists(id))
			return getZipData(id).toString();
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

		for (asset in zipAssets.keys())
			items.push(asset);

		return items;
	}

	function getSysPath(id:String):String
	{
		return rootPath + id;
	}

	function getZipData(id:String)
	{
		return Zip.unzip(zipAssets.get(id)).data;
	}
}
