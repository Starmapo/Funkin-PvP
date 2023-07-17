package data;

import haxe.io.Path;
import lime.app.Future;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.net.HTTPRequest;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import lime.utils.Bytes;
import sys.FileSystem;
import util.ZipParser;

using StringTools;

class PanLibrary extends AssetLibrary
{
	var libraries:Array<AssetLibrary>;
	var defaultLibrary:AssetLibrary;
	var sysLibrary:SysLibrary;
	var zipLibrary:ZipLibrary;
	
	public function new(?defaultLibrary:AssetLibrary)
	{
		super();
		if (defaultLibrary == null)
			defaultLibrary = Assets.getLibrary("");
		this.defaultLibrary = defaultLibrary;
		
		sysLibrary = new SysLibrary();
		
		zipLibrary = new ZipLibrary();
		
		libraries = [defaultLibrary, sysLibrary, zipLibrary];
	}
	
	public function isDirectory(path:String):Bool
	{
		return zipLibrary.isDirectory(path) || sysLibrary.isDirectory(path);
	}
	
	public function readDirectory(path:String):Array<String>
	{
		final result = zipLibrary.readDirectory(path);
		if (result.length > 0)
			return result;
			
		return sysLibrary.readDirectory(path);
	}
	
	public function reset()
	{
		zipLibrary.reset();
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
	
	override function list(type:String):Array<String>
	{
		final items:Array<String> = [];
		
		for (library in libraries)
			items.concat(library.list(type));
			
		return items;
	}
	
	override function loadAudioBuffer(id:String):Future<AudioBuffer>
	{
		for (library in libraries)
		{
			if (library.exists(id, "SOUND"))
				return library.loadAudioBuffer(id);
		}
		
		return Future.withValue(null);
	}
	
	override function loadBytes(id:String):Future<Bytes>
	{
		for (library in libraries)
		{
			if (library.exists(id, "BINARY"))
				return library.loadBytes(id);
		}
		
		return Future.withValue(null);
	}
	
	override function loadFont(id:String):Future<Font>
	{
		for (library in libraries)
		{
			if (library.exists(id, "FONT"))
				return library.loadFont(id);
		}
		
		return Future.withValue(null);
	}
	
	override function loadImage(id:String):Future<Image>
	{
		for (library in libraries)
		{
			if (library.exists(id, "IMAGE"))
				return library.loadImage(id);
		}
		
		return Future.withValue(null);
	}
	
	override function loadText(id:String):Future<String>
	{
		for (library in libraries)
		{
			if (library.exists(id, "TEXT"))
				return library.loadText(id);
		}
		
		return Future.withValue(null);
	}
}

class SysLibrary extends AssetLibrary
{
	final rootPath:String = './';
	
	public function isDirectory(path:String)
	{
		if (path == null)
			return false;
			
		path = getSysPath(path);
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}
	
	public function readDirectory(path:String):Array<String>
	{
		if (isDirectory(path))
			return FileSystem.readDirectory(getSysPath(path));
			
		return [];
	}
	
	override function exists(id:String, type:String):Bool
	{
		return FileSystem.exists(getSysPath(id));
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
		final bytes = getBytes(id);
		
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
	
	override function loadAudioBuffer(id:String):Future<AudioBuffer>
	{
		return AudioBuffer.loadFromFile(getSysPath(id));
	}
	
	override function loadBytes(id:String):Future<Bytes>
	{
		return Bytes.loadFromFile(getSysPath(id));
	}
	
	override function loadFont(id:String):Future<Font>
	{
		return Font.loadFromFile(getSysPath(id));
	}
	
	override function loadImage(id:String):Future<Image>
	{
		return Image.loadFromFile(getSysPath(id));
	}
	
	override function loadText(id:String):Future<String>
	{
		var request = new HTTPRequest<String>();
		return request.load(getSysPath(id));
	}
	
	function getSysPath(id:String):String
	{
		if (!id.startsWith(rootPath))
			return rootPath + id;
		return id;
	}
}

class ZipLibrary extends AssetLibrary
{
	final modsPath = Mods.modsPath;
	final filesLocations:Map<String, String> = new Map();
	final fileDirectories:Array<String> = [];
	final zipParsers:Map<String, ZipParser> = new Map();
	
	override function exists(id:String, type:String)
	{
		if (id == null)
			return false;
		if (filesLocations.exists(id))
			return true;
		if (fileDirectories.contains(Path.removeTrailingSlashes(id)))
			return true;
			
		return false;
	}
	
	override function getAudioBuffer(id:String):AudioBuffer
	{
		return AudioBuffer.fromBytes(getBytes(id));
	}
	
	override function getBytes(id:String)
	{
		if (!filesLocations.exists(id))
			return null;
			
		final zipPath = filesLocations.get(id);
		final zipParser = zipParsers.get(zipPath);
		final modId = Path.withoutExtension(Path.withoutDirectory(zipPath));
		
		var innerPath = id;
		if (innerPath.startsWith(modsPath))
			innerPath = innerPath.substr(Path.addTrailingSlash(modsPath).length);
		if (innerPath.startsWith(modId))
			innerPath = innerPath.substr(modId.length + 1);
			
		final fileHeader = zipParser.getLocalFileHeaderOf(innerPath);
		if (fileHeader == null)
		{
			trace('WARNING: Could not access file $innerPath from ZIP ${zipParser.fileName}.');
			return null;
		}
		final fileBytes = fileHeader.readData();
		return fileBytes;
	}
	
	override function getFont(id:String):Font
	{
		return Font.fromBytes(getBytes(id));
	}
	
	override function getImage(id:String):Image
	{
		return Image.fromBytes(getBytes(id));
	}
	
	override function getText(id:String):String
	{
		final bytes = getBytes(id);
		
		if (bytes == null)
			return null;
		else
			return bytes.getString(0, bytes.length);
	}
	
	override function list(type:String):Array<String>
	{
		final result = [];
		
		for (fileName => _ in filesLocations)
		{
			if (!result.contains(fileName))
				result.push(fileName);
		}
		
		return result;
	}
	
	/**
		Not supported!
	**/
	override function loadAudioBuffer(id:String):Future<AudioBuffer>
	{
		return Future.withValue(getAudioBuffer(id));
	}
	
	/**
		Not supported!
	**/
	override function loadBytes(id:String):Future<Bytes>
	{
		return Future.withValue(getBytes(id));
	}
	
	override function loadFont(id:String):Future<Font>
	{
		return Font.loadFromBytes(getBytes(id));
	}
	
	override function loadImage(id:String):Future<Image>
	{
		return Image.loadFromBytes(getBytes(id));
	}
	
	/**
		Not supported!
	**/
	override function loadText(id:String):Future<String>
	{
		var bytes = getBytes(id);
		
		if (bytes == null)
			return cast Future.withValue(null);
		else
			return Future.withValue(bytes.getString(0, bytes.length));
	}
	
	public function addAllZips()
	{
		final modRootContents = FileSystem.readDirectory(modsPath);
		
		for (file in modRootContents)
		{
			final filePath = Path.join([modsPath, file]);
			
			if (FileSystem.isDirectory(filePath))
				continue;
				
			if (filePath.endsWith(".zip"))
				addZipFile(filePath);
		}
	}
	
	public function addZipFile(zipPath:String)
	{
		var modId = Path.withoutExtension(Path.withoutDirectory(zipPath));
		
		var zipParser = new ZipParser(zipPath);
		
		for (fileName => fileHeader in zipParser.centralDirectoryRecords)
		{
			if (fileHeader.compressedSize == 0 || fileHeader.uncompressedSize == 0)
				continue;
				
			if (fileName.endsWith('/'))
				continue;
				
			var fullFilePath = Path.join([modsPath, modId, fileHeader.fileName]);
			filesLocations.set(fullFilePath, zipPath);
			
			var fileDirectory = Path.directory(fullFilePath);
			while (fileDirectory != "" && !fileDirectories.contains(fileDirectory))
			{
				fileDirectories.push(fileDirectory);
				fileDirectory = Path.directory(fileDirectory);
			}
		}
		
		zipParsers.set(zipPath, zipParser);
	}
	
	public function isDirectory(path:String)
	{
		if (path == null)
			return false;
			
		return fileDirectories.contains(Path.removeTrailingSlashes(path));
	}
	
	public function readDirectory(path:String)
	{
		if (path == null)
			return [];
			
		path = Path.removeTrailingSlashes(path);
		
		final result:Array<String> = [];
		
		if (fileDirectories.contains(path))
		{
			for (file in filesLocations.keys())
			{
				if (Path.directory(file) == path)
					result.push(Path.withoutDirectory(file));
			}
			for (dir in fileDirectories)
			{
				if (Path.directory(dir) == path)
					result.push(Path.withoutDirectory(dir));
			}
		}
		
		return result;
	}
	
	public function reset()
	{
		filesLocations.clear();
		fileDirectories.resize(0);
		zipParsers.clear();
		
		addAllZips();
	}
}
