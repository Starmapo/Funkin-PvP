package;

import data.Mods;
import data.PlayerSettings;
import data.game.Judgement;
import data.game.ScoreProcessor;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import haxe.io.Path;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.system.System;
import systools.win.Tools;

using StringTools;

class CoolUtil
{
	public static function getLerp(lerp:Float)
	{
		return FlxMath.bound(lerp * (60 / FlxG.updateFramerate), 0, 1);
	}

	public static function lerp(a:Float, b:Float, ratio:Float)
	{
		return FlxMath.lerp(a, b, getLerp(ratio));
	}

	public static function reverseLerp(a:Float, b:Float, ratio:Float)
	{
		return FlxMath.lerp(a, b, 1 - getLerp(ratio));
	}

	public static function createMenuBG(image:String = 'menuBG', scale:Float = 1, scrollX:Float = 0, scrollY:Float = 0)
	{
		var bg = new FlxSprite(0, 0, Paths.getImage('menus/$image'));
		bg.scrollFactor.set(scrollX, scrollY);
		if (scale != 1)
		{
			bg.scale.set(scale, scale);
			bg.updateHitbox();
		}
		bg.screenCenter();
		bg.antialiasing = true;
		return bg;
	}

	/**
		Plays the menu music.
		@param volume The volume that the music should start at. Defaults to 1, or full volume.
	**/
	public static function playMenuMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.getMusic("Gettin' Freaky"), volume);
	}

	public static function playPvPMusic(volume:Float = 1)
	{
		if (Mods.pvpMusic.length == 0)
			return;

		var music = Mods.pvpMusic[FlxG.random.int(0, Mods.pvpMusic.length - 1)];
		FlxG.sound.playMusic(Paths.getMusic(Path.join([music, 'audio.ogg'])), volume);
	}

	/**
		Plays the scroll sound for menus.
		@param volume The volume that the sound should play at. Defaults to 1, or full volume.
	**/
	public static function playScrollSound(volume:Float = 1)
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/scrollMenu'), volume);
		sound.persist = true;
		return sound;
	}

	/**
		Plays the confirm sound for menus.
		@param volume The volume that the sound should play at. Defaults to 1, or full volume.
	**/
	public static function playConfirmSound(volume:Float = 1)
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/confirmMenu'), volume);
		sound.persist = true;
		return sound;
	}

	/**
		Plays the cancel sound for menus.
		@param volume The volume that the sound should play at. Defaults to 1, or full volume.
	**/
	public static function playCancelSound(volume:Float = 1)
	{
		var sound = FlxG.sound.play(Paths.getSound('menus/cancelMenu'), volume);
		sound.persist = true;
		return sound;
	}

	/**
		Centers a group of objects on the screen.
		@param group 	The group that contains objects.
		@param axes 	The axes to center it to.
	**/
	@:generic
	public static function screenCenterGroup<T:FlxObject>(group:FlxTypedGroup<T>, axes:FlxAxes = XY)
	{
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

	/**
		Returns the width of an FlxGroup.
		@param group The group that contains objects.
	**/
	@:generic
	public static function getGroupWidth<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		if (group.length == 0)
			return 0;

		return getArrayMaxX(group.members) - getArrayMinX(group.members);
	}

	/**
		Returns the height of an FlxGroup.
		@param group The group that contains objects.
	**/
	@:generic
	public static function getGroupHeight<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		if (group.length == 0)
			return 0;

		return getArrayMaxY(group.members) - getArrayMinY(group.members);
	}

	@:generic
	public static function getArrayWidth<T:FlxObject>(array:Array<T>):Float
	{
		if (array.length == 0)
			return 0;

		return getArrayMaxX(array) - getArrayMinX(array);
	}

	/**
		Returns an array containing all the values of this map.
		@param map The map.
	**/
	@:generic
	public static function getMapArray<T1, T2>(map:Map<T1, T2>):Array<T2>
	{
		var array:Array<T2> = [for (value in map.iterator()) value];
		return array;
	}

	/**
		Returns if anything has been inputted. This includes the keyboard, gamepads, and the mouse.
	**/
	public static function anyJustInputted()
	{
		return (PlayerSettings.anyJustPressed() || FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed || FlxG.mouse.justPressedMiddle
			|| FlxG.mouse.justPressedRight);
	}

	public static function formatOrdinal(num:Int)
	{
		if (num <= 0)
			return Std.string(num);

		switch (num % 100)
		{
			case 11, 12, 13:
				return num + "th";
		}

		return switch (num % 10)
		{
			case 1:
				num + "st";
			case 2:
				num + "nd";
			case 3:
				num + "rd";
			default:
				num + "th";
		}
	}

	public static function getBeatSnapColor(snap:Int)
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

	public static function inBetween(num:Float, start:Float, end:Float)
	{
		return num >= start && num <= end;
	}

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

	public static function getGradeFromAccuracy(accuracy:Float)
	{
		if (accuracy >= 100)
			return 'X';
		else if (accuracy >= 99)
			return 'SS';
		else if (accuracy >= 95)
			return 'S';
		else if (accuracy >= 90)
			return 'A';
		else if (accuracy >= 80)
			return 'B';
		else if (accuracy >= 70)
			return 'C';

		return 'D';
	}

	public static function getFCText(scoreProcessor:ScoreProcessor)
	{
		if (scoreProcessor.currentJudgements[MISS] > 0
			|| scoreProcessor.currentJudgements[SHIT] > 0
			|| scoreProcessor.totalJudgementCount == 0)
			return '';
		if (scoreProcessor.currentJudgements[BAD] > 0)
			return ' [FC]';
		if (scoreProcessor.currentJudgements[GOOD] > 0)
			return ' [Good FC]';
		if (scoreProcessor.currentJudgements[SICK] > 0)
			return ' [Sick FC]';

		return ' [Marvelous FC]';
	}

	public static function getColorFromArray(array:Array<Int>)
	{
		if (array == null || array.length < 3)
			return new FlxColor();

		return FlxColor.fromRGB(array[0], array[1], array[2]);
	}

	public static function getDominantColor(sprite:FlxSprite):FlxColor
	{
		if (sprite.pixels == null)
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

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);
		return dumbArray;
	}

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
			return blah;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

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

	public static function getObjectDirectly(objectName:String):Dynamic
	{
		return getVarInArray(FlxG.state, objectName);
	}

	public static function getVersion():String
	{
		return FlxG.stage.application.meta["version"];
	}

	public static function getVersionWarning(version:String)
	{
		var splitCurVersion = getVersion().split('.');
		var curMajor = Std.parseInt(splitCurVersion[0]);

		var splitVersion = version.split('.');
		var major = (splitVersion[0] != null && splitVersion[0].length > 0) ? Std.parseInt(splitVersion[0]) : null;
		if (major == null)
			major = curMajor;

		if (major < curMajor)
			return '[WARNING: This mod was made for a previous major release (v$major) and might not function properly!]\n';
		if (major > curMajor)
			return '[WARNING: This mod was made for a future major release (v$major) and might not function properly!]\n';

		return '';
	}

	public static function sortAlphabetically(a:String, b:String, order:Int = FlxSort.ASCENDING)
	{
		if (a == null)
			a = '';
		if (b == null)
			b = '';

		a = a.toLowerCase();
		b = b.toLowerCase();

		if (a < b)
			return order;
		if (a > b)
			return -order;
		return 0;
	}

	public static function containsAny(s:String, values:Array<String>)
	{
		if (values != null)
		{
			for (value in values)
			{
				if (s.contains(value))
					return true;
			}
		}
		return false;
	}

	public static function getBGGraphic(name:String, groupDirectory:String)
	{
		var groupName = name;
		name = FlxStringUtil.validate(name);
		var graphicKey = name + '_edit';
		if (FlxG.bitmap.checkCache(graphicKey))
			return FlxG.bitmap.get(graphicKey);

		var thickness = 4;

		var graphic = Paths.getImage('bg/$name', groupDirectory, false, false, graphicKey);
		if (graphic == null)
			graphic = Paths.getImage('bg/unknown', '', false, false, graphicKey);

		var text = new FlxText(0, graphic.height - thickness, graphic.width, groupName);
		text.setFormat('VCR OSD Mono', 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.updateHitbox();
		text.y -= text.height;

		var textBG = new FlxSprite(text.x, text.y).makeGraphic(Std.int(text.width), Std.int(graphic.height - text.y), FlxColor.GRAY);
		graphic.bitmap.copyPixels(textBG.pixels, new Rectangle(0, 0, textBG.width, textBG.height), new Point(textBG.x, textBG.y), null, null, true);
		textBG.destroy();

		graphic.bitmap.copyPixels(text.pixels, new Rectangle(0, 0, text.width, text.height), new Point(text.x, text.y), null, null, true);
		text.destroy();

		var mask = FlxG.bitmap.get('groupMask');
		if (mask == null)
		{
			var sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupMask');
			FlxSpriteUtil.drawRoundRect(sprite, 0, 0, sprite.width, sprite.height, 20, 20, FlxColor.BLACK);
			mask = sprite.graphic;
			mask.destroyOnNoUse = false;
			sprite.destroy();
		}

		graphic.bitmap.copyChannel(mask.bitmap, new Rectangle(0, 0, mask.width, mask.height), new Point(), ALPHA, ALPHA);

		var outline = FlxG.bitmap.get('groupOutline');
		if (outline == null)
		{
			var sprite = new FlxSprite().makeGraphic(158, 158, FlxColor.TRANSPARENT, false, 'groupOutline');
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
	 * Gets the macro class created by hscript-improved for an abstract / enum
	 */
	public static inline function getMacroAbstractClass(className:String)
	{
		return Type.resolveClass('${className}_HSC');
	}

	public static function restart()
	{
		#if windows
		var app = Sys.programPath();
		var workingDir = Sys.getCwd();

		var result = Tools.createProcess(app, 'Test.hx', workingDir, false, false);
		if (result == 0)
			System.exit(1337);
		else
			throw "Failed to restart. Error code: " + result;
		#end
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

typedef NameInfo =
{
	var name:String;
	var ?mod:String;
}
