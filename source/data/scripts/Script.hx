package data.scripts;

import data.char.CharacterInfo;
import data.char.IconInfo;
import data.skin.JudgementSkin;
import data.skin.NoteSkin;
import data.song.CameraFocus;
import data.song.EventObject;
import data.song.LyricStep;
import data.song.NoteInfo;
import data.song.ScrollVelocity;
import data.song.Song;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.Constraints.IMap;
import haxe.Json;
import haxe.ds.EnumValueMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import hxcodec.flixel.FlxVideo;
import hxcodec.flixel.FlxVideoSprite;
import lime.app.Application;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import sprites.AnimatedSprite;
import sprites.DancingSprite;
import sprites.game.BGSprite;
import sprites.game.Character;
import states.FNFState;
import states.PlayState;
import subStates.FNFSubState;
import ui.game.Note;
import ui.game.NoteSplash;
import ui.game.Receptor;

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
		setVariable('mod', mod);
		setVariable('window', Application.current.window);

		setVariable('FUNCTION_CONTINUE', FUNCTION_CONTINUE);
		setVariable('FUNCTION_STOP', FUNCTION_STOP);
		setVariable('FUNCTION_BREAK', FUNCTION_BREAK);
		setVariable('FUNCTION_STOP_BREAK', FUNCTION_STOP_BREAK);

		setVariable('Date', Date);
		setVariable('EnumValueMap', EnumValueMap);
		setVariable('IMap', IMap);
		setVariable('IntMap', IntMap);
		setVariable('Json', Json);
		setVariable('Math', Math);
		setVariable('ObjectMap', ObjectMap);
		setVariable('Reflect', Reflect);
		setVariable('Std', Std);
		setVariable('StringMap', StringMap);
		setVariable('StringTools', StringTools);
		setVariable('Sys', Sys);
		setVariable('Type', Type);

		setVariable('Application', Application);
		setVariable('Assets', Assets);
		setVariable('BitmapData', BitmapData);
		setVariable('BlendMode', CoolUtil.getMacroAbstractClass("openfl.display.BlendMode"));
		setVariable('Point', Point);
		setVariable('Rectangle', Rectangle);

		setVariable('FlxAngle', FlxAngle);
		setVariable('FlxAtlasFrames', FlxAtlasFrames);
		setVariable('FlxAxes', CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"));
		setVariable('FlxBackdrop', FlxBackdrop);
		setVariable('FlxBasic', FlxBasic);
		setVariable('FlxCamera', FlxCamera);
		setVariable('FlxColor', CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"));
		setVariable('FlxDestroyUtil', FlxDestroyUtil);
		setVariable('FlxEase', FlxEase);
		setVariable('FlxG', FlxG);
		setVariable('FlxGraphic', FlxGraphic);
		setVariable('FlxGroup', FlxGroup);
		setVariable('FlxMath', FlxMath);
		setVariable('FlxObject', FlxObject);
		setVariable('FlxPoint', CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"));
		setVariable('FlxRect', FlxRect);
		setVariable('FlxRuntimeShader', FlxRuntimeShader);
		setVariable('FlxSort', FlxSort);
		setVariable('FlxSound', FlxSound);
		setVariable('FlxSprite', FlxSprite);
		setVariable('FlxSpriteGroup', FlxSpriteGroup);
		setVariable('FlxText', FlxText);
		setVariable('FlxTextAlign', CoolUtil.getMacroAbstractClass("flixel.text.FlxTextAlign"));
		setVariable('FlxTextBorderStyle', FlxTextBorderStyle);
		setVariable('FlxTextFormat', FlxTextFormat);
		setVariable('FlxTilemap', FlxTilemap);
		setVariable('FlxTimer', FlxTimer);
		setVariable('FlxTrail', FlxTrail);
		setVariable('FlxTween', FlxTween);
		setVariable('FlxTweenType', CoolUtil.getMacroAbstractClass("flixel.tweens.FlxTweenType"));
		setVariable('FlxTypedGroup', FlxTypedGroup);
		setVariable('FlxTypedSpriteGroup', FlxTypedSpriteGroup);
		setVariable('FlxVideo', FlxVideo);
		setVariable('FlxVideoSprite', FlxVideoSprite);

		setVariable('AnimatedSprite', AnimatedSprite);
		setVariable('BGSprite', BGSprite);
		setVariable('CameraFocus', CameraFocus);
		setVariable('Character', Character);
		setVariable('CharacterInfo', CharacterInfo);
		setVariable('Controls', Controls);
		setVariable('CoolUtil', CoolUtil);
		setVariable('DancingSprite', DancingSprite);
		setVariable('EventObject', EventObject);
		setVariable('FNFState', FNFState);
		setVariable('FNFSubState', FNFSubState);
		setVariable('IconInfo', IconInfo);
		setVariable('JudgementSkin', JudgementSkin);
		setVariable('LyricStep', LyricStep);
		setVariable('Mods', Mods);
		setVariable('Note', Note);
		setVariable('NoteInfo', NoteInfo);
		setVariable('NoteSkin', NoteSkin);
		setVariable('NoteSplash', NoteSplash);
		setVariable('Paths', Paths);
		setVariable('PlayerSettings', PlayerSettings);
		setVariable('PlayState', PlayState);
		setVariable('Receptor', Receptor);
		setVariable('ScrollVelocity', ScrollVelocity);
		setVariable('Settings', Settings);
		setVariable('Song', Song);
		setVariable('TimingPoint', TimingPoint);

		setVariable("close", function()
		{
			closed = true;
		});
		setVariable("import", function(className:String)
		{
			var splitClassName = [for (e in className.split(".")) e.trim()];
			var realClassName = splitClassName.join(".");
			var cl = Type.resolveClass(realClassName);
			var en = Type.resolveEnum(realClassName);
			if (cl == null && en == null)
				onError('Class / Enum at "$realClassName" does not exist.');
			else
			{
				if (en != null)
				{
					var enumThingy = {};
					for (c in en.getConstructors())
						Reflect.setField(enumThingy, c, en.createByName(c));

					setVariable(splitClassName[splitClassName.length - 1], enumThingy);
				}
				else
					setVariable(splitClassName[splitClassName.length - 1], cl);
			}
		});
	}
}
