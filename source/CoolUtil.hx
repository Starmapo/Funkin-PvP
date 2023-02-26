package;

import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

class CoolUtil
{
	public static function getLerp(lerp:Float)
	{
		return lerp * (60 / FlxG.updateFramerate);
	}

	public static function lerp(a:Float, b:Float, ratio:Float)
	{
		return FlxMath.lerp(a, b, getLerp(ratio));
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
		Returns the width of an FlxGroup.
		@param group The group that contains objects.
	**/
	public static function getGroupWidth(group:FlxTypedGroup<Dynamic>):Float
	{
		if (group.length == 0)
			return 0;

		return getGroupMaxX(cast group) - getGroupMinX(cast group);
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

	static function getGroupMaxX(group:FlxTypedGroup<FlxObject>):Float
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

	static function getGroupMinX(group:FlxTypedGroup<FlxObject>):Float
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
}
