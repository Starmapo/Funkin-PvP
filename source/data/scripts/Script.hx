package data.scripts;

import data.char.CharacterInfo;
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
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
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
import ui.game.Note;
import ui.game.NoteSplash;
import ui.game.Receptor;

using StringTools;

// Some stuff here is from Yoshi Engine or Psych Engine
class Script implements IFlxDestroyable
{
	public static final FUNCTION_STOP:String = "FUNCTIONSTOP";
	public static final FUNCTION_CONTINUE:String = "FUNCTIONCONTINUE";
	public static final FUNCTION_STOP_SCRIPTS:String = "FUNCTIONSTOPSCRIPTS";

	public var interp:Interp;
	public var expr:Expr;
	public var path:String;
	public var mod:String;
	public var closed:Bool = false;

	public function new(path:String, mod:String)
	{
		if (mod == null || mod.length == 0)
			mod = Mods.currentMod;
		this.path = path;
		this.mod = mod;

		interp = new Interp();
		setStartingVariables();

		var script = Paths.getContent(path);
		if (script == null || script.length < 1)
			return;

		var parser = new Parser();
		parser.allowTypes = true;
		try
		{
			expr = parser.parseString(script);
		}
		catch (e)
		{
			if (!FlxG.fullscreen)
				Application.current.window.alert('Failed to parse the script located at "$path".\n${Std.string(e)} at line ${parser.line}', 'Script Error');
			trace(e.message);
		}

		if (expr == null)
			return;

		try
		{
			interp.execute(expr);
		}
		catch (e)
		{
			if (!FlxG.fullscreen)
				Application.current.window.alert(e.message, 'Script Error');
			trace(e.message);
		}
	}

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

	public function setVariable(name:String, value:Dynamic)
	{
		if (interp == null)
			return;

		interp.variables.set(name, value);
	}

	public function getVariable(name:String)
	{
		if (interp == null)
			return null;

		return interp.variables.get(name);
	}

	public function destroy()
	{
		interp = null;
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

	function onError(message:String)
	{
		trace(message);
	}

	function setStartingVariables()
	{
		setVariable('this', this);
		setVariable('window', Application.current.window);

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
		setVariable('BlendMode', BlendModeHelper);
		setVariable('Point', Point);
		setVariable('Rectangle', Rectangle);

		setVariable('FlxAngle', FlxAngle);
		setVariable('FlxAssets', FlxAssets);
		setVariable('FlxAtlasFrames', FlxAtlasFrames);
		setVariable('FlxAxes', FlxAxesHelper);
		setVariable('FlxBackdrop', FlxBackdrop);
		setVariable('FlxBasic', FlxBasic);
		setVariable('FlxCamera', FlxCamera);
		setVariable('FlxColor', FlxColorHelper);
		setVariable('FlxDestroyUtil', FlxDestroyUtil);
		setVariable('FlxEase', FlxEase);
		setVariable('FlxG', FlxG);
		setVariable('FlxGraphic', FlxGraphic);
		setVariable('FlxGraphicsShader', FlxGraphicsShader);
		setVariable('FlxGroup', FlxGroup);
		setVariable('FlxMath', FlxMath);
		setVariable('FlxObject', FlxObject);
		setVariable('FlxPoint', FlxPointHelper);
		setVariable('FlxRect', FlxRect);
		setVariable('FlxRuntimeShader', FlxRuntimeShader);
		setVariable('FlxShader', FlxShader);
		setVariable('FlxSort', FlxSort);
		setVariable('FlxSound', FlxSound);
		setVariable('FlxSprite', FlxSprite);
		setVariable('FlxSpriteGroup', FlxSpriteGroup);
		setVariable('FlxState', FlxState);
		setVariable('FlxSubState', FlxSubState);
		setVariable('FlxText', FlxText);
		setVariable('FlxTextAlign', FlxTextAlignHelper);
		setVariable('FlxTextBorderStyle', FlxTextBorderStyle);
		setVariable('FlxTextFormat', FlxTextFormat);
		setVariable('FlxTilemap', FlxTilemap);
		setVariable('FlxTimer', FlxTimer);
		setVariable('FlxTrail', FlxTrail);
		setVariable('FlxTween', FlxTween);
		setVariable('FlxTypedGroup', FlxTypedGroup);
		setVariable('FlxTypedSpriteGroup', FlxTypedSpriteGroup);

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
