package backend.util;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import lime.app.Application;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.system.System;
import systools.win.Tools;

using StringTools;

/**
	A class containing a bunch of cool utilities.
**/
class CoolUtil
{
	/**
		Shows an alert for the user to see, unless fullscreen is on (as that could break stuff).
	**/
	public static function alert(?message:String, ?title:String):Void
	{
		if (!FlxG.fullscreen)
			Application.current.window.alert(message, title);
		var traceText = (title.length > 0 ? title + ': ' : '') + message;
		if (traceText.length > 0)
			trace(traceText);
	}
	
	public static function angleFromKeys(keys:Array<FlxKey>):Float
	{
		if (keys == null)
			keys = [UP, LEFT, DOWN, RIGHT];
		if (keys.length < 4)
			return 0;
			
		final up = FlxG.keys.checkStatus(keys[0], PRESSED);
		final left = FlxG.keys.checkStatus(keys[1], PRESSED);
		final down = FlxG.keys.checkStatus(keys[2], PRESSED);
		final right = FlxG.keys.checkStatus(keys[3], PRESSED);
		
		var angle:Float = 0;
		if (up)
		{
			angle = 270;
			if (left)
				angle -= 45;
			else if (right)
				angle += 45;
		}
		else if (down)
		{
			angle = 90;
			if (left)
				angle += 45;
			else if (right)
				angle -= 45;
		}
		else if (left)
			angle = 180;
			
		return angle;
	}
	
	/**
		Creates a menu background sprite.

		@param	image	The image name to use. Defaults to `menuBG`.
		@param	scale	The scaling factor. Defaults to `1`, or no scaling.
		@param	scrollX	The horizontal scroll factor. Defaults to `0`, or no scrolling.
		@param	scrollY The vertical scroll factor. Defaults to `0`, or no scrolling.
	**/
	public static function createMenuBG(image:String = 'menuBG', scale:Float = 1, scrollX:Float = 0, scrollY:Float = 0):FlxSprite
	{
		var bg = new FlxSprite(0, 0, Paths.getImage('menus/$image'));
		bg.scrollFactor.set(scrollX, scrollY);
		if (scale != 1)
		{
			bg.scale.set(scale, scale);
			bg.updateHitbox();
		}
		bg.screenCenter();
		bg.antialiasing = Settings.antialiasing;
		return bg;
	}
	
	/**
		Returns the height of an array of objects.
	**/
	@:generic
	public static function getArrayHeight<T:FlxObject>(array:Array<T>):Float
	{
		if (array == null || array.length == 0)
			return 0;
			
		return getArrayMaxY(array) - getArrayMinY(array);
	}
	
	/**
		Returns the width of an array of objects.
	**/
	@:generic
	public static function getArrayWidth<T:FlxObject>(array:Array<T>):Float
	{
		if (array == null || array.length == 0)
			return 0;
			
		return getArrayMaxX(array) - getArrayMinX(array);
	}
	
	public static function getAtlasName(name:String):String
	{
		var atlasName = name;
		
		while (FlxMath.inBounds(atlasName.charCodeAt(atlasName.length - 1), '0'.code, '9'.code))
			atlasName = atlasName.substr(0, atlasName.length - 1);
			
		return atlasName;
	}
	
	/**
		Gets the color of a beat snap. The default is `FlxColor.WHITE`.
	**/
	public static function getBeatSnapColor(snap:Int):FlxColor
	{
		return switch (snap)
		{
			case 2:
				0xFFE10B01;
			case 3:
				0xFF9B51E0;
			case 4:
				0xFF0587E5;
			case 6:
				0xFFBB6BD9;
			case 8:
				0xFFE9B736;
			case 12:
				0xFFD34B8C;
			case 16:
				0xFFFFE76B;
			default:
				FlxColor.WHITE;
		}
	}
	
	/**
		Returns a color from an array containing RGB values. It should have atleast 3 elements to work.
	**/
	public static function getColorFromArray(array:Array<Int>):FlxColor
	{
		if (array == null || array.length < 3)
			return FlxColor.WHITE;
			
		return FlxColor.fromRGB(array[0], array[1], array[2]);
	}
	
	/**
		Gets the dominant color of a sprite's frame.
	**/
	public static function getDominantColor(sprite:FlxSprite):FlxColor
	{
		if (sprite == null || sprite.pixels == null)
			return FlxColor.BLACK;
			
		var countByColor:Map<Int, Int> = [];
		var x = 0;
		var y = 0;
		var width = sprite.pixels.width;
		var height = sprite.pixels.height;
		if (sprite.frame != null)
		{
			var frame = sprite.frame.frame;
			x = Std.int(frame.x);
			y = Std.int(frame.y);
			width = Std.int(frame.width);
			height = Std.int(frame.height);
		}
		for (col in x...x + width)
		{
			for (row in y...y + height)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}
		countByColor[FlxColor.BLACK] = 0;
		
		var maxCount = 0;
		var maxKey = FlxColor.BLACK;
		for (key in countByColor.keys())
		{
			if (countByColor[key] > maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}
	
	/**
		Returns a group graphic for character/song select screens.
	**/
	@:access(flixel.util.FlxSave)
	public static function getGroupGraphic(name:String, groupDirectory:String):FlxGraphic
	{
		final graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);
			
		var graphic = Paths.getImage('bg/$name', groupDirectory, graphicKey);
		if (graphic == null)
		{
			final unknownKey = '::groupUnknown::_edit';
			if (FlxG.bitmap.checkCache(unknownKey))
				return FlxG.bitmap.get(unknownKey);
			graphic = Paths.getImage('bg/unknown', '', unknownKey);
		}
		
		final thickness = 4;
		
		final text = new FlxText(0, graphic.height - thickness, graphic.width, name);
		text.setFormat(Paths.FONT_VCR, 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.updateHitbox();
		text.y -= text.height;
		
		final textBG = new FlxSprite(text.x, text.y).makeGraphic(Std.int(text.width), Std.int(graphic.height - text.y), FlxColor.GRAY);
		graphic.bitmap.copyPixels(textBG.pixels, new Rectangle(0, 0, textBG.width, textBG.height), new Point(textBG.x, textBG.y), null, null, true);
		textBG.destroy();
		
		graphic.bitmap.copyPixels(text.pixels, new Rectangle(0, 0, text.width, text.height), new Point(text.x, text.y), null, null, true);
		text.destroy();
		
		var mask = FlxG.bitmap.get('groupMask');
		if (mask == null)
		{
			final sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupMask');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.BLACK);
			mask = sprite.graphic;
			mask.destroyOnNoUse = false;
			sprite.destroy();
		}
		
		graphic.bitmap.copyChannel(mask.bitmap, new Rectangle(0, 0, mask.width, mask.height), new Point(), ALPHA, ALPHA);
		
		var outline = FlxG.bitmap.get('groupOutline');
		if (outline == null)
		{
			final sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupOutline');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.TRANSPARENT,
				{thickness: thickness, color: FlxColor.WHITE});
			outline = sprite.graphic;
			outline.destroyOnNoUse = false;
			sprite.destroy();
		}
		
		graphic.bitmap.copyPixels(outline.bitmap, new Rectangle(0, 0, outline.width, outline.height), new Point(), null, null, true);
		
		return graphic;
	}
	
	/**
		Returns the height of an `FlxGroup`.
	**/
	@:generic
	public static function getGroupHeight<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		if (group == null || group.length == 0)
			return 0;
			
		return getArrayMaxY(group.members) - getArrayMinY(group.members);
	}
	
	/**
		Returns the width of an `FlxGroup`.
	**/
	@:generic
	public static function getGroupWidth<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		if (group == null || group.length == 0)
			return 0;
			
		return getArrayMaxX(group.members) - getArrayMinX(group.members);
	}
	
	/**
		Adjusts a lerp value depending on the current frame rate. Also bounds it between 0 and 1.
	**/
	public static function getLerp(lerp:Float):Float
	{
		return FlxMath.bound(lerp * (60 / FlxG.updateFramerate), 0, 1);
	}
	
	/**
		Gets the macro class created by `util.HScriptMacro` for an abstract/enum.
	**/
	public static inline function getMacroAbstractClass(className:String):Class<Dynamic>
	{
		return Type.resolveClass('${className}_HSC');
	}
	
	/**
		Returns a `NameInfo` structure from a name, describing the mod directory if there is one.

		@param	defaultMod	If no mod is specified in the name, this will be used as the mod directory.
	**/
	public static function getNameInfo(name:String, defaultMod:String = ''):NameInfo
	{
		var realName = name;
		var mod = defaultMod;
		
		var colonIndex = name.indexOf(':');
		if (colonIndex > 0)
		{
			realName = name.substr(colonIndex + 1);
			mod = name.substr(0, colonIndex);
		}
		
		return {
			name: realName,
			mod: mod
		}
	}
	
	/**
		Returns an array containing all the values of this map.
	**/
	@:generic
	public static function getMapArray<T1, T2>(map:Map<T1, T2>):Array<T2>
	{
		if (map == null)
			return null;
			
		var array:Array<T2> = [for (value in map.iterator()) value];
		return array;
	}
	
	/**
		Gets an object in the current state.
	**/
	public static function getObjectDirectly(objectName:String):Dynamic
	{
		return getVarInArray(FlxG.state, objectName);
	}
	
	/**
		Gets a property in an array of strings indicating an object.

		@param	getProperty	If true, the second to last variable will be returned.
	**/
	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?getProperty:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0]);
		var end = killMe.length;
		if (getProperty)
			end = killMe.length - 1;
			
		for (i in 1...end)
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
			
		return coverMeInPiss;
	}
	
	/**
		Gets a variable from an instance. Supports array access.
	**/
	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1)
		{
			var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
			
			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}
		
		return Reflect.getProperty(instance, variable);
	}
	
	/**
		Gets the program's version.
	**/
	public static function getVersion():String
	{
		return FlxG.stage.application.meta["version"];
	}
	
	/**
		Returns the linear interpolation of two numbers, adjusting the ratio depending on the frame rate.

		@param	a		The starting number.
		@param	b		The end number.
		@param	ratio	The ratio for the linear interpolation.
	**/
	public static function lerp(a:Float, b:Float, ratio:Float):Float
	{
		return FlxMath.lerp(a, b, getLerp(ratio));
	}
	
	/**
		Returns an array of integers from `min` to `max`.
	**/
	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);
		return dumbArray;
	}
	
	/**
		Plays the cancel sound for menus.

		@param	volume	The volume that the sound should play at. Defaults to `1`, or full volume.
		@return	The new `FlxSound` object.
	**/
	public static function playCancelSound(volume:Float = 1):FlxSound
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/cancelMenu'), volume);
		sound.persist = true;
		return sound;
	}
	
	/**
		Plays the confirm sound for menus.

		@param	volume	The volume that the sound should play at. Defaults to `1`, or full volume.
		@return	The new `FlxSound` object.
	**/
	public static function playConfirmSound(volume:Float = 1):FlxSound
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/confirmMenu'), volume);
		sound.persist = true;
		return sound;
	}
	
	/**
		Plays the scroll sound for menus.

		@param	volume	The volume that the sound should play at. Defaults to `1`, or full volume.
		@return	The new `FlxSound` object.
	**/
	public static function playScrollSound(volume:Float = 1):FlxSound
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/scrollMenu'), volume);
		sound.persist = true;
		return sound;
	}
	
	/**
		Restarts the program. Only works on Windows.
	**/
	public static function restart():Void
	{
		#if windows
		var app = Sys.programPath();
		var workingDir = Sys.getCwd();
		
		var result = Tools.createProcess(app, 'Test.hx', workingDir, false, false);
		if (result == 0)
			System.exit(result);
		else
			throw "Failed to restart. Error code: " + result;
		#end
	}
	
	/**
		Returns the linear interpolation of two numbers, adjusting the ratio depending on the frame rate and then
		subtracting it from `1`.

		@param	a		The starting number.
		@param	b		The end number.
		@param	ratio	The ratio for the linear interpolation.
	**/
	public static function reverseLerp(a:Float, b:Float, ratio:Float):Float
	{
		return FlxMath.lerp(a, b, 1 - getLerp(ratio));
	}
	
	/**
		Centers a group of objects on the screen.

		@param	axes	The axes to center it to.
	**/
	@:generic
	public static function screenCenterGroup<T:FlxObject>(group:FlxTypedGroup<T>, axes:FlxAxes = XY):Void
	{
		if (group == null)
			return;
			
		var centerX = (FlxG.width - getGroupWidth(group)) / 2;
		var centerY = (FlxG.height - getGroupHeight(group)) / 2;
		for (member in group)
		{
			if (axes.x)
				member.x += centerX;
			if (axes.y)
				member.y += centerY;
		}
	}
	
	public static function setFramerate(framerate:Int)
	{
		if (framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = framerate;
			FlxG.drawFramerate = framerate;
		}
		else
		{
			FlxG.drawFramerate = framerate;
			FlxG.updateFramerate = framerate;
		}
	}
	
	/**
		Sets a variable of an instance. Supports array access.
	**/
	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1)
		{
			var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				if (i >= shit.length - 1)
					blah[leNum] = value;
				else
					blah = blah[leNum];
			}
			return value;
		}
		
		Reflect.setProperty(instance, variable, value);
		return value;
	}
	
	public static function tweenColor(sprite:FlxSprite, duration:Float = 1, fromColor:FlxColor, toColor:FlxColor, ?options:TweenOptions)
	{
		return FlxTween.num(0, 1, duration, options, function(n)
		{
			sprite.color = FlxColor.interpolate(fromColor, toColor, n);
		});
	}
	
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		var range = max - min + 1;
		
		if (value < min)
			value += range * Std.int((min - value) / range + 1);
			
		return min + (value - min) % range;
	}
	
	@:generic
	static function getArrayMaxX<T:FlxObject>(array:Array<T>):Float
	{
		var value = Math.NEGATIVE_INFINITY;
		for (member in array)
		{
			if (member == null)
				continue;
				
			var maxX:Float = member.x + member.width;
			
			if (maxX > value)
				value = maxX;
		}
		return value;
	}
	
	@:generic
	static function getArrayMinX<T:FlxObject>(array:Array<T>):Float
	{
		var value = Math.POSITIVE_INFINITY;
		for (member in array)
		{
			if (member == null)
				continue;
				
			var minX:Float = member.x;
			
			if (minX < value)
				value = minX;
		}
		return value;
	}
	
	@:generic
	static function getArrayMaxY<T:FlxObject>(array:Array<T>):Float
	{
		var value = Math.NEGATIVE_INFINITY;
		for (member in array)
		{
			if (member == null)
				continue;
				
			var maxY:Float = member.y + member.height;
			
			if (maxY > value)
				value = maxY;
		}
		return value;
	}
	
	@:generic
	static function getArrayMinY<T:FlxObject>(array:Array<T>):Float
	{
		var value = Math.POSITIVE_INFINITY;
		for (member in array)
		{
			if (member == null)
				continue;
				
			var minY:Float = member.y;
			
			if (minY < value)
				value = minY;
		}
		return value;
	}
}

/**
	Info for a name along with its directory. Use `CoolUtil.getNameInfo` to get this structure.

	Examples:

	- `"bf"`		->	{name: `"bf"`, mod: `""`}
	- `"fnf:gf"`	->	{name: `"gf"`, mod: `"fnf"`}
**/
typedef NameInfo =
{
	var name:String;
	var mod:String;
}
