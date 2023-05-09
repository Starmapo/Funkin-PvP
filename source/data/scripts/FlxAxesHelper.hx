package data.scripts;

import flixel.util.FlxAxes;

class FlxAxesHelper
{
	public static var X = FlxAxes.X;
	public static var Y = FlxAxes.Y;
	public static var XY = FlxAxes.XY;
	public static var NONE = FlxAxes.NONE;

	public static inline function fromBools(x:Bool, y:Bool):FlxAxes
	{
		return FlxAxes.fromBools(x, y);
	}

	public static inline function fromString(axes:String):FlxAxes
	{
		return FlxAxes.fromString(axes);
	}
}
