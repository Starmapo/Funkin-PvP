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
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import haxe.io.Path;

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
		return FlxG.sound.play(Paths.getSound('menus/scrollMenu'), volume);
	}

	/**
		Plays the confirm sound for menus.
		@param volume The volume that the sound should play at. Defaults to 1, or full volume.
	**/
	public static function playConfirmSound(volume:Float = 1)
	{
		return FlxG.sound.play(Paths.getSound('menus/confirmMenu'), volume);
	}

	/**
		Plays the cancel sound for menus.
		@param volume The volume that the sound should play at. Defaults to 1, or full volume.
	**/
	public static function playCancelSound(volume:Float = 1)
	{
		return FlxG.sound.play(Paths.getSound('menus/cancelMenu'), volume);
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

		return getGroupMaxX(group) - getGroupMinX(group);
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

		return getGroupMaxY(group) - getGroupMinY(group);
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

	public static function getNameInfo(name:String):NameInfo
	{
		var realName = name;
		var mod = '';

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

	@:generic
	static function getGroupMaxX<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		var value = Math.NEGATIVE_INFINITY;
		for (member in group)
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
	static function getGroupMinX<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		var value = Math.POSITIVE_INFINITY;
		for (member in group)
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
	static function getGroupMaxY<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		var value = Math.NEGATIVE_INFINITY;
		for (member in group)
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
	static function getGroupMinY<T:FlxObject>(group:FlxTypedGroup<T>):Float
	{
		var value = Math.POSITIVE_INFINITY;
		for (member in group)
		{
			if (member == null)
				continue;

			var minY:Float = member.y;

			if (minY < value)
				value = minY;
		}
		return value;
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
}

typedef NameInfo =
{
	var name:String;
	var ?mod:String;
}
