package backend.scripts;

import lime.app.Application;
import tea.SScript;

using StringTools;

class SScriptObject extends Script
{
	/**
		Prevents these classes from being imported, for safety measures.
	**/
	public static final DENY_CLASSES:Array<String> = [
		"Sys",
		"Type",
		"backend.DiscordClient",
		"backend.util.UnsafeUtil",
		"cpp.NativeProcess",
		"cpp.NativeSocket",
		"cpp.NativeSsl",
		"cpp.NativeSys",
		"discord_rpc.DiscordRpc",
		"flixel.FlxG",
		"flixel.addons.ui.U",
		"flixel.util.FlxSharedObject",
		"haxe.Http",
		"lime.system.System",
		"lime.tools.CLIHelper",
		"lime.tools.CommandHelper",
		"lime.tools.ConfigHelper",
		"lime.tools.HXProject",
		"lime.tools.TizenHelper",
		"lime.ui.FileDialog",
		"openfl.Lib",
		"openfl.filesystem.File",
		"openfl.filesystem.FileStream",
		"openfl.net.FileReference",
		"openfl.net.SharedObject",
		"states.menus.CreditsState",
		"states.menus.UpdateState",
		"sys.FileSystem",
		"sys.Http",
		"sys.db.Mysql",
		"sys.db.Sqlite",
		"sys.db.SqliteConnection",
		"sys.db.SqliteResultSet",
		"sys.io.File",
		"sys.io.Process",
		"sys.net.Host",
		"sys.net.Socket",
		"sys.net.SocketInput",
		"sys.net.SocketOutput",
		"sys.net.UdpSocket",
		"sys.ssl.Socket",
		"sys.ssl.SocketInput",
		"sys.ssl.SocketOutput",
		"systools.Browser",
		"systools.Loader",
		"systools.Registry",
		"systools.win.Tools",
		"systools.win.Tray"
	];
	
	public var script:SScript;
	
	override function initScript(path:String)
	{
		if (script != null)
			return;
			
		script = new SScript();
		@:privateAccess
		script.scriptFile = path;
		#if debug
		script.traces = true;
		#end
		
		preset();
		
		script.doString(Paths.getContent(path), path);
	}
	
	override function get(name:String):Dynamic
	{
		if (script == null)
			return null;
			
		return script.get(name);
	}
	
	override function set(name:String, value:Dynamic):Dynamic
	{
		if (script == null)
			return null;
			
		return script.set(name, value);
	}
	
	override function exists(name:String)
	{
		if (script == null)
			return false;
			
		return script.exists(name);
	}
	
	override function destroy()
	{
		super.destroy();
		
		if (script != null)
		{
			script.destroy();
			script = null;
		}
	}
	
	override function preset()
	{
		if (script == null)
			return;
			
		super.preset();
		
		script.unset('File');
		script.unset('FileSystem');
		script.unset('Sys');
		
		script.setClass(haxe.ds.EnumValueMap);
		script.setClass(haxe.ds.IntMap);
		script.setClass(haxe.ds.ObjectMap);
		script.setClass(Reflect);
		script.setClass(haxe.ds.StringMap);
		
		script.setClass(openfl.utils.Assets);
		set('BlendMode', CoolUtil.getMacroAbstractClass("openfl.display.BlendMode"));
		
		set('FlxColor', CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"));
		set('FlxG', FlxGHelper);
		script.setClass(flixel.group.FlxGroup);
		script.setClass(flixel.math.FlxMath);
		script.setClass(flixel.sound.FlxSound);
		script.setClass(flixel.FlxSprite);
		script.setClass(flixel.group.FlxSpriteGroup);
		script.setClass(flixel.text.FlxText);
		script.setClass(flixel.util.FlxTimer);
		script.setClass(flixel.tweens.FlxTween);
		script.setClass(flixel.group.FlxGroup.FlxTypedGroup);
		script.setClass(flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup);
		
		script.setClass(AnimatedSprite);
		script.setClass(objects.game.BGSprite);
		script.setClass(objects.game.Character);
		script.setClass(Controls);
		script.setClass(CoolUtil);
		script.setClass(objects.DancingSprite);
		script.setClass(Mods);
		script.setClass(Paths);
		script.setClass(Settings);
		
		script.set("debugPrint", Reflect.makeVarArgs(function(el)
		{
			var inf = script.interp.posInfos();
			var posInfo = inf.fileName + ':' + inf.lineNumber + ': ';
			var max = el.length - 1;
			for (i in 0...el.length)
			{
				posInfo += Std.string(el[i]);
				if (i < max)
					posInfo += ', ';
			}
			Main.showInternalNotification(posInfo);
			trace(posInfo);
		}));
		set("close", function()
		{
			closed = true;
		});
		
		for (c in DENY_CLASSES)
			script.notAllowedClasses.push(Type.resolveClass(c));
	}
	
	override function callFunc(func:String, ?args:Array<Any>):Dynamic
	{
		if (script == null || !exists(func))
			return null;
			
		var call = script.call(func, args);
		
		if (call.exceptions.length > 0)
		{
			for (e in call.exceptions)
				Main.showNotification(e.message, ERROR);
		}
		
		return call.returnValue;
	}
}
