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
import util.StringUtil;

using StringTools;

class PanLibrary extends AssetLibrary
{
	var libraries:Array<AssetLibrary>;
	var defaultLibrary:AssetLibrary;
	var sysLibrary:SysLibrary;
	
	public function new(?defaultLibrary:AssetLibrary)
	{
		super();
		if (defaultLibrary == null)
			defaultLibrary = Assets.getLibrary("");
		this.defaultLibrary = defaultLibrary;
		
		sysLibrary = new SysLibrary();
		
		libraries = [defaultLibrary, sysLibrary];
	}
	
	override function exists(id:String, type:String):Bool
	{
		for (library in libraries)
		{
			if (library.exists(id, type))
				return true;
		}
		
		return false;
	}
	
	override function getAudioBuffer(id:String):AudioBuffer
	{
		for (library in libraries)
		{
			if (library.exists(id, "SOUND"))
				return library.getAudioBuffer(id);
		}
		
		return null;
	}
	
	override function getBytes(id:String):Bytes
	{
		for (library in libraries)
		{
			if (library.exists(id, "BINARY"))
				return library.getBytes(id);
		}
		
		return null;
	}
	
	override function getFont(id:String):Font
	{
		for (library in libraries)
		{
			if (library.exists(id, "FONT"))
				return library.getFont(id);
		}
		
		return null;
	}
	
	override function getImage(id:String):Image
	{
		for (library in libraries)
		{
			if (library.exists(id, "IMAGE"))
				return library.getImage(id);
		}
		
		return null;
	}
	
	override function getText(id:String):String
	{
		for (library in libraries)
		{
			if (library.exists(id, "TEXT"))
				return library.getText(id);
		}
		
		return null;
	}
	
	/**
		`type` isn't supported for FileSystem checks!
	**/
	override function list(type:String):Array<String>
	{
		var items:Array<String> = [];
		
		for (library in libraries)
			items.concat(library.list(type));
			
		return items;
	}
}

class SysLibrary extends AssetLibrary
{
	final rootPath:String = './';
	final typeExtensions:Map<AssetType, Array<String>> = [
		FONT => ["ttf, otf"],
		IMAGE => ["png"],
		MUSIC => ["ogg", "wav"],
		SOUND => ["ogg", "wav"]
	];
	
	override function exists(id:String, type:String):Bool
	{
		var path = getSysPath(id);
		if (FileSystem.exists(path))
		{
			var requestedType = type != null ? cast(type, AssetType) : null;
			return isType(path, requestedType);
		}
		
		return false;
	}
	
	override function getAudioBuffer(id:String):AudioBuffer
	{
		return AudioBuffer.fromFile(getSysPath(id));
	}
	
	override function getBytes(id:String):Bytes
	{
		return Bytes.fromFile(getSysPath(id));
	}
	
	override function getFont(id:String):Font
	{
		return Font.fromFile(getSysPath(id));
	}
	
	override function getImage(id:String):Image
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
	
	/**
		Not supported.
	**/
	override function list(type:String):Array<String>
	{
		return [];
	}
	
	function getSysPath(id:String):String
	{
		return rootPath + id;
	}
	
	function isType(path:String, ?type:AssetType)
	{
		var extension = Path.extension(path);
		if (extension.length < 1)
			return false;
			
		if (type == null || type == BINARY || type == TEXT)
			return true;
			
		var extensions = typeExtensions.get(type);
		return extensions != null && StringUtil.endsWithAny(extension, extensions);
	}
}
