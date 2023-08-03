package backend.util;

import haxe.io.Path;
import sys.FileSystem;

using StringTools;

class UnsafeUtil
{
	/**
		Creates a directory at the specified path, if it doesn't already exist.
	**/
	public static function createDirectory(directory:String)
	{
		if (directory == null)
			return;
		if (!directory.startsWith("./"))
			directory = "./" + directory;
		if (FileSystem.exists(directory))
			return;
		FileSystem.createDirectory(directory);
	}
	
	/**
		Deletes a directory, also handling the deletion of files inside of it.
	**/
	public static function deleteDirectory(directory:String)
	{
		if (directory == null)
			return;
		if (!directory.startsWith("./"))
			directory = "./" + directory;
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
			return;
			
		var files = FileSystem.readDirectory(directory);
		for (file in files)
		{
			var path = Path.join([directory, file]);
			if (FileSystem.isDirectory(path))
				deleteDirectory(path);
			else
				FileSystem.deleteFile(path);
		}
		FileSystem.deleteDirectory(directory);
	}
}
