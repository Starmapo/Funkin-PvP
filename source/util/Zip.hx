package util;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.zip.Entry;
import haxe.zip.Reader;
import lime._internal.format.Deflate;

class Zip
{
	var input:Input;
	var reader:Reader;

	public function new(i)
	{
		input = i;
		reader = new Reader(i);
	}

	public static function getZipContent(path:String):List<Entry>
	{
		if (!Paths.exists(path))
			return null;
		return readZip(Paths.getBytes(path));
	}

	public static function readZip(i:Bytes)
	{
		var r = new Reader(new BytesInput(i));
		return r.read();
	}

	public static function unzip(f:Entry):Entry
	{
		if (f == null)
			return f;
		if (f.compressed)
		{
			f.data = Deflate.decompress(f.data);
			f.compressed = false;
			f.dataSize = f.fileSize;
		}
		return f;
	}
}
