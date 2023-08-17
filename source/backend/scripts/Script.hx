package backend.scripts;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import lime.app.Application;

using StringTools;

/**
	Base class for script objects.
**/
class Script implements IFlxDestroyable
{
	/**
		Default return value.
	**/
	public static final FUNCTION_CONTINUE:String = "::FUNCTION_CONTINUE::";
	
	/**
		Stops a function, if supported.
	**/
	public static final FUNCTION_STOP:String = "::FUNCTION_STOP::";
	
	/**
		Breaks the script iterator, preventing any more return values.
	**/
	public static final FUNCTION_BREAK:String = "::FUNCTION_BREAK::";
	
	/**
		Breaks the script iterator and returns `FUNCTION_STOP`.
	**/
	public static final FUNCTION_STOP_BREAK:String = "::FUNCTION_STOP_BREAK::";
	
	public static function getScript(path:String, mod:String)
	{
		return new SScriptObject(path, mod);
	}
	
	/**
		The path of the script file.
	**/
	public var path:String;
	
	/**
		The mod directory of this script file.
	**/
	public var mod:String;
	
	/**
		Whether this script was closed or not. Closed scripts won't execute functions.
	**/
	public var closed:Bool = false;
	
	public function new(path:String, mod:String)
	{
		if (mod == null || mod.length == 0)
			mod = Mods.currentMod;
			
		this.path = path;
		this.mod = mod;
		
		initScript(path);
	}
	
	/**
		Calls `func` with the arguments `args` in the script.
	**/
	public function call(func:String, ?args:Array<Any>):Dynamic
	{
		if (closed)
			return FUNCTION_CONTINUE;
			
		var lastMod = Mods.currentMod;
		Mods.currentMod = mod;
		
		var r:Dynamic = callFunc(func, args);
		
		Mods.currentMod = lastMod;
		
		return r;
	}
	
	/**
		Gets a variable in the script.
	**/
	public function get(name:String):Dynamic
	{
		return null;
	}
	
	/**
		Sets a variable in the script.
	**/
	public function set(name:String, value:Dynamic):Dynamic
	{
		return null;
	}
	
	public function exists(name:String):Bool
	{
		return false;
	}
	
	/**
		Frees up memory.
	**/
	public function destroy() {}
	
	function initScript(path:String) {}
	
	function callFunc(func:String, ?args:Array<Any>):Dynamic
	{
		return null;
	}
	
	function preset()
	{
		set('FUNCTION_CONTINUE', FUNCTION_CONTINUE);
		set('FUNCTION_STOP', FUNCTION_STOP);
		set('FUNCTION_BREAK', FUNCTION_BREAK);
		set('FUNCTION_STOP_BREAK', FUNCTION_STOP_BREAK);
		
		set('mod', Mods.getMod(mod));
		set('modID', mod);
	}
}
