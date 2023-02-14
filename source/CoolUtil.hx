package;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class CoolUtil
{
	public static function getGroupWidth(group:FlxTypedGroup<Dynamic>):Float
	{
		if (group.length == 0)
			return 0;

		return getGroupMaxX(cast group) - getGroupMinX(cast group);
	}

	static function getGroupMaxX(group:FlxTypedGroup<FlxSprite>):Float
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

	static function getGroupMinX(group:FlxTypedGroup<FlxSprite>):Float
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
