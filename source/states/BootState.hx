package states;

import backend.AudioSwitchFix;
import backend.WindowsAPI;
import backend.util.UnsafeUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import sys.FileSystem;

using StringTools;

class BootState extends FNFState
{
	/**
		The state to switch to after the game finishes booting up.
	**/
	static var initialState:Class<FlxState> = states.menus.TitleState;
	
	var bg:FlxSprite;
	var loadingText:FlxText;
	var loadingBG:FlxSprite;
	var loadingSteps:Array<LoadingStep> = [];
	var aborted:Bool = false;
	var wantedText:String = 'Loading...';
	
	override function create()
	{
		initGame();
		
		FlxG.camera.bgColor = 0xFFCAFF4D;
		
		bg = new FlxSprite(0, 0, Paths.getImage('menus/loading/funkay'));
		bg.setGraphicSize(0, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = Settings.antialiasing;
		add(bg);
		
		loadingBG = new FlxSprite().makeGraphic(FlxG.width, 1, FlxColor.BLACK);
		loadingBG.alpha = 0.8;
		add(loadingBG);
		
		loadingText = new FlxText(0, FlxG.height, FlxG.width);
		loadingText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingText.y -= loadingText.height;
		loadingText.screenCenter(X);
		add(loadingText);
		
		loadingSteps.push({
			name: 'Loading Save Data',
			func: loadSave
		});
		loadingSteps.push({
			name: 'Loading Mods',
			func: loadMods
		});
		
		var i = 0;
		new FlxTimer().start(0.1, function(tmr)
		{
			if (loadingSteps.length > 0)
			{
				var step = loadingSteps.shift();
				updateText(step.name + '... ' + Math.floor((i / loadingSteps.length) * 100) + '%');
				step.func();
				
				if (aborted)
				{
					CoolUtil.playCancelSound();
					return;
				}
				
				i++;
				tmr.reset();
			}
			else
			{
				updateText('Finished!');
				FlxG.camera.fade(FlxColor.BLACK, Main.getTransitionTime(), false, exit, true);
				CoolUtil.playConfirmSound();
			}
		});
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		loadingText.text = wantedText;
		loadingText.y = FlxG.height - loadingText.height;
		loadingBG.setPosition(loadingText.x, loadingText.y - 2);
		loadingBG.setGraphicSize(FlxG.width, Std.int(loadingText.height + 4));
		loadingBG.updateHitbox();
	}
	
	override function destroy()
	{
		super.destroy();
		bg = null;
		loadingText = null;
		loadingBG = null;
		loadingSteps = null;
	}
	
	function initGame()
	{
		WindowsAPI.setWindowToDarkMode(); // change window to dark mode
		AudioSwitchFix.init();
		
		Paths.init();

		backend.util.HaxeUIUtil.initToolkit();
		
		#if !macro
		DiscordClient.initialize();
		#end
		
		FlxG.fixedTimestep = false; // allow elapsed time to be variable
		FlxG.debugger.toggleKeys = [GRAVEACCENT, BACKSLASH]; // remove F2 from debugger toggle keys
		FlxG.game.focusLostFramerate = 60; // 60 fps instead of 10 when focus is lost
		FlxG.mouse.useSystemCursor = true; // use system cursor instead of HaxeFlixel one
		FlxG.mouse.visible = false; // hide mouse by default
		// create custom transitions
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, FlxPoint.get(0, 1));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 1, FlxPoint.get(0, 1));
		
		/*
			Interp.getRedirects["Int"] = function(obj:Dynamic, name:String):Dynamic
			{
				var c:FlxColor = obj;
				switch (name)
				{
					case "alpha":
						return c.alpha;
					case "alphaFloat":
						return c.alphaFloat;
					case "black":
						return c.black;
					case "blue":
						return c.blue;
					case "blueFloat":
						return c.blueFloat;
					case "brightness":
						return c.brightness;
					case "cyan":
						return c.cyan;
					case "to24Bit":
						return c.to24Bit;
					case "getAnalogousHarmony":
						return c.getAnalogousHarmony;
					case "getColorInfo":
						return c.getColorInfo;
					case "getComplementHarmony":
						return c.getComplementHarmony;
					case "getDarkened":
						return c.getDarkened;
					case "getInverted":
						return c.getInverted;
					case "getLightened":
						return c.getLightened;
					case "toHexString":
						return c.toHexString;
					case "getSplitComplementHarmony":
						return c.getSplitComplementHarmony;
					case "getTriadicHarmony":
						return c.getTriadicHarmony;
					case "toWebString":
						return c.toWebString;
					case "green":
						return c.green;
					case "greenFloat":
						return c.greenFloat;
					case "hue":
						return c.hue;
					case "lightness":
						return c.lightness;
					case "magenta":
						return c.magenta;
					case "red":
						return c.red;
					case "redFloat":
						return c.redFloat;
					case "rgb":
						return c.rgb;
					case "setCMYK":
						return c.setCMYK;
					case "setHSB":
						return c.setHSB;
					case "setHSL":
						return c.setHSL;
					case "setRGB":
						return c.setRGB;
					case "setRGBFloat":
						return c.setRGBFloat;
					case "saturation":
						return c.saturation;
					case "yellow":
						return c.yellow;
				}
				var a:FlxAxes = obj;
				switch (name)
				{
					case "x":
						return a.x;
					case "y":
						return a.y;
				}
				return null;
			}
			Interp.setRedirects["Int"] = function(obj:Dynamic, name:String, val:Dynamic):Dynamic
			{
				var c:FlxColor = obj;
				switch (name)
				{
					case "alpha":
						return c.alpha = val;
					case "alphaFloat":
						return c.alphaFloat = val;
					case "black":
						return c.black = val;
					case "blue":
						return c.blue = val;
					case "blueFloat":
						return c.blueFloat = val;
					case "brightness":
						return c.brightness = val;
					case "cyan":
						return c.cyan = val;
					case "green":
						return c.green = val;
					case "greenFloat":
						return c.greenFloat = val;
					case "hue":
						return c.hue = val;
					case "lightness":
						return c.lightness = val;
					case "magenta":
						return c.magenta = val;
					case "red":
						return c.red = val;
					case "redFloat":
						return c.redFloat = val;
					case "rgb":
						return c.rgb = val;
					case "saturation":
						return c.saturation = val;
					case "yellow":
						return c.yellow = val;
				}
				return null;
			}
			Interp.getRedirects["flixel.math.FlxBasePoint"] = function(obj:Dynamic, name:String):Dynamic
			{
				var p:FlxPoint = obj;
				switch (name)
				{
					case "add":
						return p.add;
					case "addNew":
						return p.addNew;
					case "addPoint":
						return p.addPoint;
					case "addToFlash":
						return p.addToFlash;
					case "bounce":
						return p.bounce;
					case "bounceWithFriction":
						return p.bounceWithFriction;
					case "ceil":
						return p.ceil;
					case "clone":
						return p.clone;
					case "copyFrom":
						return p.copyFrom;
					case "copyFromFlash":
						return p.copyFromFlash;
					case "copyTo":
						return p.copyTo;
					case "copyToFlash":
						return p.copyToFlash;
					case "crossProductLength":
						return p.crossProductLength;
					case "degrees":
						return p.degrees;
					case "degreesBetween":
						return p.degreesBetween;
					case "degreesFrom":
						return p.degreesFrom;
					case "degreesTo":
						return p.degreesTo;
					case "dist":
						return p.dist;
					case "distSquared":
						return p.distSquared;
					case "distanceTo":
						return p.distanceTo;
					case "dot":
						return p.dot;
					case "dotProduct":
						return p.dotProduct;
					case "dotProdWithNormalizing":
						return p.dotProdWithNormalizing;
					case "dx":
						return p.dx;
					case "dy":
						return p.dy;
					case "findIntersection":
						return p.findIntersection;
					case "findIntersectionInBounds":
						return p.findIntersectionInBounds;
					case "floor":
						return p.floor;
					case "inCoords":
						return p.inCoords;
					case "inRect":
						return p.inRect;
					case "isNormalized":
						return p.isNormalized;
					case "isParallel":
						return p.isParallel;
					case "isPerpendicular":
						return p.isPerpendicular;
					case "isValid":
						return p.isValid;
					case "isZero":
						return p.isZero;
					case "leftNormal":
						return p.leftNormal;
					case "length":
						return p.length;
					case "lengthSquared":
						return p.lengthSquared;
					case "lx":
						return p.lx;
					case "ly":
						return p.ly;
					case "negate":
						return p.negate;
					case "negateNew":
						return p.negateNew;
					case "normalize":
						return p.normalize;
					case "perpProduct":
						return p.perpProduct;
					case "pivotDegrees":
						return p.pivotDegrees;
					case "pivotRadians":
						return p.pivotRadians;
					case "projectTo":
						return p.projectTo;
					case "projectToNormalized":
						return p.projectToNormalized;
					case "radians":
						return p.radians;
					case "radiansBetween":
						return p.radiansBetween;
					case "radiansFrom":
						return p.radiansFrom;
					case "radiansTo":
						return p.radiansTo;
					case "ratio":
						return p.ratio;
					case "rightNormal":
						return p.rightNormal;
					case "rotateByDegrees":
						return p.rotateByDegrees;
					case "rotateByRadians":
						return p.rotateByRadians;
					case "rotateWithTrig":
						return p.rotateWithTrig;
					case "round":
						return p.round;
					case "rx":
						return p.rx;
					case "ry":
						return p.ry;
					case "setPolarDegrees":
						return p.setPolarDegrees;
					case "setPolarRadians":
						return p.setPolarRadians;
					case "sign":
						return p.sign;
					case "scale":
						return p.scale;
					case "scaleNew":
						return p.scaleNew;
					case "scalePoint":
						return p.scalePoint;
					case "subtract":
						return p.subtract;
					case "subtractFromFlash":
						return p.subtractFromFlash;
					case "subtractNew":
						return p.subtractNew;
					case "subtractPoint":
						return p.subtractPoint;
					case "transform":
						return p.transform;
					case "truncate":
						return p.truncate;
					case "zero":
						return p.zero;
				}
				return null;
			}
			Interp.setRedirects["flixel.math.FlxBasePoint"] = function(obj:Dynamic, name:String, val:Dynamic):Dynamic
			{
				var p:FlxPoint = obj;
				switch (name)
				{
					case "degrees":
						return p.degrees = val;
					case "length":
						return p.length = val;
					case "radians":
						return p.radians = val;
				}
				return null;
			};
		 */
		
		UnsafeUtil.deleteDirectory(".temp");
	}
	
	function loadSave()
	{
		Settings.loadData(); // load settings
		Controls.init(); // initialize controls
		
		Application.current.onExit.add(function(_)
		{
			Settings.saveData();
			#if !macro
			DiscordClient.shutdown();
			#end
			UnsafeUtil.deleteDirectory(".temp");
			Sys.exit(0);
		});
	}
	
	function loadMods()
	{
		if (!FileSystem.exists(Mods.modsPath))
		{
			updateText("Mods folder not detected. If you deleted it, please restore it or download the game again.");
			aborted = true;
			return;
		}
		
		Mods.reloadMods();
		
		var hasFNF = false;
		for (mod in Mods.currentMods)
		{
			if (mod.id == "fnf")
			{
				hasFNF = true;
				return;
			}
		}
		if (!hasFNF)
		{
			updateText("Base FNF mod not detected. If you deleted it, please restore it or download the game again.");
			aborted = true;
		}
	}
	
	function exit()
	{
		FlxG.switchState(Type.createInstance(initialState, []));
	}
	
	function updateText(text:String)
	{
		wantedText = text;
	}
}

typedef LoadingStep =
{
	var name:String;
	var func:Void->Void;
}
