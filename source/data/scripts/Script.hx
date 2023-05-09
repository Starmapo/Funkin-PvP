package data.scripts;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import lime.app.Application;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
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

class Script
{
	public var interp:Interp;
	public var path:String;
	public var mod:String;
	public var closed:Bool = false;

	public function new(path:String, mod:String)
	{
		this.path = path;
		this.mod = mod;

		interp = new Interp();

		var script = Paths.getContent(path);
		if (script == null || script.length < 1)
			return;

		var parser = new Parser();
		parser.allowTypes = true;
		var expr:Expr = null;
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

		setStartingVariables();
	}

	public function execute(func:String, ?args:Array<Any>)
	{
		var lastMod = Mods.currentMod;
		Mods.currentMod = mod;

		var r = executeFunc(func, args);

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

	function executeFunc(func:String, ?args:Array<Any>)
	{
		if (interp == null)
			return null;

		var f = interp.variables.get(func);
		if (f != null && Reflect.isFunction(f))
		{
			if (args == null || args.length < 1)
				return f();
			else
				return Reflect.callMethod(null, f, args);
		}

		return null;
	}

	function setStartingVariables()
	{
		setVariable('this', this);
		setVariable('window', Application.current.window);

		setVariable('Date', Date);
		setVariable('Json', Json);
		setVariable('Math', Math);
		setVariable('Reflect', Reflect);
		setVariable('Std', Std);
		setVariable('StringTools', StringTools);
		setVariable('Sys', Sys);
		setVariable('Type', Type);

		setVariable('Application', Application);
		setVariable('Assets', Assets);
		setVariable('BitmapData', BitmapData);
		setVariable('BlendMode', BlendMode);
		setVariable('Point', Point);
		setVariable('Rectangle', Rectangle);

		setVariable('FlxAssets', FlxAssets);
		setVariable('FlxAxes', FlxAxes);
		setVariable('FlxBackdrop', FlxBackdrop);
		setVariable('FlxCamera', FlxCamera);
		setVariable('FlxColor', FlxColor);
		setVariable('FlxEase', FlxEase);
		setVariable('FlxG', FlxG);
		setVariable('FlxGraphic', FlxGraphic);
		setVariable('FlxGroup', FlxGroup);
		setVariable('FlxMath', FlxMath);
		setVariable('FlxObject', FlxObject);
		setVariable('FlxPoint', FlxPoint);
		setVariable('FlxRect', FlxRect);
		setVariable('FlxSound', FlxSound);
		setVariable('FlxSprite', FlxSprite);
		setVariable('FlxSpriteGroup', FlxSpriteGroup);
		setVariable('FlxSubState', FlxSubState);
		setVariable('FlxText', FlxText);
		setVariable('FlxTextAlign', FlxTextAlign);
		setVariable('FlxTextBorderStyle', FlxTextBorderStyle);
		setVariable('FlxTextFormat', FlxTextFormat);
		setVariable('FlxTilemap', FlxTilemap);
		setVariable('FlxTimer', FlxTimer);
		setVariable('FlxTween', FlxTween);
		setVariable('FlxTypedGroup', FlxTypedGroup);
		setVariable('FlxTypedSpriteGroup', FlxTypedSpriteGroup);

		setVariable('AnimatedSprite', AnimatedSprite);
		setVariable('BGSprite', BGSprite);
		setVariable('Character', Character);
		setVariable('CoolUtil', CoolUtil);
		setVariable('DancingSprite', DancingSprite);
		setVariable('FNFState', FNFState);
		setVariable('Note', Note);
		setVariable('NoteSplash', NoteSplash);
		setVariable('Paths', Paths);
		setVariable('PlayerSettings', PlayerSettings);
		setVariable('PlayState', PlayState);
		setVariable('Receptor', Receptor);
		setVariable('Settings', Settings);

		setVariable("close", function()
		{
			closed = true;
		});
	}
}
