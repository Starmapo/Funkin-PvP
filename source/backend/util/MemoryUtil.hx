package backend.util;

#if cpp
import cpp.vm.Gc;
#end

class MemoryUtil
{
	public static function clearMinor()
	{
		#if cpp
		Gc.run(false);
		#end
	}
	
	public static function clearMajor()
	{
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end
	}
}
