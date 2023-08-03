package backend.util;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;

class ZipUtil
{
	/**
	 * Runs the 'Inflate' decompression algorithm on the raw compressed bytes
	 * and returns the uncompressed data.
	 *
	 * @param bytes A raw block of compressed bytes
	 * @return A raw block of uncompressed bytes
	 */
	public static function unzipBytes(compressedBytes:Bytes)
	{
		var returnBuf = new BytesBuffer();
		
		// Initialize the Inflate algorithm.
		var bytesInput = new BytesInput(compressedBytes);
		var inflater = new InflateImpl(bytesInput, false, false);
		
		// Read and inflate the bytes in chunks of 65,535 bytes.
		var unzipBuf = Bytes.alloc(65535);
		var bytesRead = inflater.readBytes(unzipBuf, 0, unzipBuf.length);
		while (bytesRead == unzipBuf.length)
		{
			returnBuf.addBytes(unzipBuf, 0, bytesRead);
			bytesRead = inflater.readBytes(unzipBuf, 0, unzipBuf.length);
		}
		// Add the last chunk of bytes to the return buffer.
		returnBuf.addBytes(unzipBuf, 0, bytesRead);
		
		// Return the uncompressed bytes.
		return returnBuf.getBytes();
	}
}
