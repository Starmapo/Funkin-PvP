package backend.scripts;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import lime.app.Application;

using StringTools;

/**
	An object which runs HScript code.
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
	
	/**
		The HScript interpretator for this object.
	**/
	public var interp:Interp;
	
	/**
		The HScript expression for this object.
	**/
	public var expr:Expr;
	
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
		
		interp = new Interp();
		interp.script = this;
		setStartingVariables();
		
		var script = Paths.getContent(path);
		if (script == null || script.length < 1)
			return;
			
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		try
		{
			expr = parser.parseString(script);
		}
		catch (e)
		{
			CoolUtil.alert('Failed to parse the script located at "$path".\n${Std.string(e)} at line ${parser.line}', 'Script Error');
		}
		
		if (expr == null)
			return;
			
		try
		{
			interp.execute(expr);
		}
		catch (e)
		{
			CoolUtil.alert(e.message, 'Script Error');
		}
	}
	
	/**
		Executes `func` with the arguments `args`.
	**/
	public function execute(func:String, ?args:Array<Any>):Dynamic
	{
		if (closed)
			return FUNCTION_CONTINUE;
			
		var lastMod = Mods.currentMod;
		Mods.currentMod = mod;
		
		var r:Dynamic = executeFunc(func, args);
		
		Mods.currentMod = lastMod;
		
		return r;
	}
	
	/**
		Sets a variable in the interpretator.
	**/
	public function setVariable(name:String, value:Dynamic)
	{
		if (interp == null)
			return;
			
		interp.variables.set(name, value);
	}
	
	/**
		Gets a variable from the interpretator.
	**/
	public function getVariable(name:String)
	{
		if (interp == null)
			return null;
			
		return interp.variables.get(name);
	}
	
	/**
		Frees up memory.
	**/
	public function destroy()
	{
		interp = null;
		expr = null;
	}
	
	/**
		Called when there's an error in the HScript interpretator.
	**/
	public function onError(message:String)
	{
		Main.showInternalNotification(message, ERROR);
		trace(message);
	}
	
	function executeFunc(func:String, ?args:Array<Any>):Dynamic
	{
		if (interp == null)
			return null;
			
		var f = interp.variables.get(func);
		if (f != null && Reflect.isFunction(f))
		{
			try
			{
				if (args == null || args.length < 1)
					return f();
				else
					return Reflect.callMethod(null, f, args);
			}
			catch (e)
			{
				onError(e.message);
				closed = true;
			}
		}
		
		return null;
	}
	
	function setStartingVariables()
	{
		setVariable('this', this);
		setVariable('mod', Mods.getMod(mod));
		setVariable('modID', mod);
		setVariable('window', Application.current.window);
		
		setVariable('FUNCTION_CONTINUE', FUNCTION_CONTINUE);
		setVariable('FUNCTION_STOP', FUNCTION_STOP);
		setVariable('FUNCTION_BREAK', FUNCTION_BREAK);
		setVariable('FUNCTION_STOP_BREAK', FUNCTION_STOP_BREAK);
		
		setVariable('Date', Date);
		setVariable('EnumValueMap', haxe.ds.EnumValueMap);
		setVariable('IntMap', haxe.ds.IntMap);
		setVariable('Json', haxe.Json);
		setVariable('Math', Math);
		setVariable('ObjectMap', haxe.ds.ObjectMap);
		setVariable('Reflect', Reflect);
		setVariable('Std', Std);
		setVariable('StringMap', haxe.ds.StringMap);
		setVariable('StringTools', StringTools);
		
		setVariable('Application', Application);
		
		setVariable('Assets', openfl.utils.Assets);
		setVariable('BitmapData', openfl.display.BitmapData);
		setVariable('BlendMode', CoolUtil.getMacroAbstractClass("openfl.display.BlendMode"));
		setVariable('Point', openfl.geom.Point);
		setVariable('Rectangle', openfl.geom.Rectangle);
		
		setVariable('FlxAngle', flixel.math.FlxAngle);
		setVariable('FlxAtlasFrames', flixel.graphics.frames.FlxAtlasFrames);
		setVariable('FlxAxes', CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"));
		setVariable('FlxBackdrop', flixel.addons.display.FlxBackdrop);
		setVariable('FlxBasic', flixel.FlxBasic);
		setVariable('FlxCamera', flixel.FlxCamera);
		setVariable('FlxColor', CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"));
		setVariable('FlxDestroyUtil', flixel.util.FlxDestroyUtil);
		setVariable('FlxEase', flixel.tweens.FlxEase);
		setVariable('FlxG', FlxGHelper);
		setVariable('FlxGraphic', flixel.graphics.FlxGraphic);
		setVariable('FlxGroup', flixel.group.FlxGroup);
		setVariable('FlxMath', flixel.math.FlxMath);
		setVariable('FlxObject', flixel.FlxObject);
		setVariable('FlxPoint', CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"));
		setVariable('FlxRect', flixel.math.FlxRect);
		setVariable('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		setVariable('FlxSort', flixel.util.FlxSort);
		setVariable('FlxSound', flixel.sound.FlxSound);
		setVariable('FlxSprite', flixel.FlxSprite);
		setVariable('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		setVariable('FlxText', flixel.text.FlxText);
		setVariable('FlxTextAlign', CoolUtil.getMacroAbstractClass("flixel.text.FlxTextAlign"));
		setVariable('FlxTextBorderStyle', flixel.text.FlxText.FlxTextBorderStyle);
		setVariable('FlxTextFormat', flixel.text.FlxText.FlxTextFormat);
		setVariable('FlxTilemap', flixel.tile.FlxTilemap);
		setVariable('FlxTimer', flixel.util.FlxTimer);
		setVariable('FlxTrail', flixel.addons.effects.FlxTrail);
		setVariable('FlxTween', flixel.tweens.FlxTween);
		setVariable('FlxTweenType', CoolUtil.getMacroAbstractClass("flixel.tweens.FlxTweenType"));
		setVariable('FlxTypedGroup', flixel.group.FlxGroup.FlxTypedGroup);
		setVariable('FlxTypedSpriteGroup', flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup);
		setVariable('FlxVideoSprite', hxcodec.flixel.FlxVideoSprite);
		
		setVariable('AnimatedSprite', AnimatedSprite);
		setVariable('BGSprite', objects.game.BGSprite);
		setVariable('Character', objects.game.Character);
		setVariable('Controls', backend.Controls);
		setVariable('CoolUtil', CoolUtil);
		setVariable('DancingSprite', objects.DancingSprite);
		setVariable('FNFState', FNFState);
		setVariable('FNFSubState', FNFSubState);
		setVariable('Mods', Mods);
		setVariable('Note', objects.game.Note);
		setVariable('NoteSplash', objects.game.NoteSplash);
		setVariable('Paths', Paths);
		setVariable('PlayerSettings', PlayerSettings);
		setVariable('PlayState', states.PlayState);
		setVariable('Receptor', objects.game.Receptor);
		setVariable('Settings', Settings);
		setVariable('Song', backend.structures.song.Song);
		
		setVariable("close", function()
		{
			closed = true;
		});
		setVariable("import", function(className:String)
		{
			var splitClassName = [for (e in className.split(".")) e.trim()];
			className = splitClassName.join(".");
			if (className.length < 1)
				return;
			if (DENY_CLASSES.contains(className))
			{
				onError("You can't import class / enum `" + className + "`.");
				return;
			}
			
			var cl = Type.resolveClass(className);
			if (cl != null)
				setVariable(splitClassName[splitClassName.length - 1], cl);
			else
			{
				var en = Type.resolveEnum(className);
				if (en != null)
				{
					var enumThingy = {};
					for (c in en.getConstructors())
						Reflect.setField(enumThingy, c, en.createByName(c));
						
					setVariable(splitClassName[splitClassName.length - 1], enumThingy);
				}
				else
					onError("Couldn't find class / enum at `" + className + "`.");
			}
		});
	}
}
