package data.song;

import flixel.util.FlxStringUtil;

class CameraFocus extends JsonObject implements ITimingObject
{
	/**
		The time in milliseconds for when the camera focus begins.
	**/
	public var startTime:Float;

	/**
		What character to focus on.
	**/
	public var char:CameraFocusChar;

	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0);
		char = readInt(data.char, 0, 0, 2);
	}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([LabelValuePair.weak("startTime", startTime), LabelValuePair.weak("char", char)]);
	}
}

enum abstract CameraFocusChar(Int) from Int to Int
{
	var OPPONENT = 0;
	var BF = 1;
	var GF = 2;
}
