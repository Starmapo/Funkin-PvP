package util;

#if macro
import haxe.macro.Compiler;

class ScriptsMacro
{
	public static function addAdditionalClasses()
	{
		var classes = [
			"flixel", "openfl.net", "DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern"
		];
		#if sys
		classes.push('sys');
		#end
		for (cl in classes)
			Compiler.include(cl);
	}
}
#end
