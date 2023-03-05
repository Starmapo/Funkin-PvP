package data.song;

import flixel.util.FlxStringUtil;

class CameraFocus extends JsonObject
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
		startTime = readFloat(data.startTime, 0, 0, null, 3);
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

@:enum abstract CameraFocusChar(Int) from Int to Int
{
	var BF = 0;
	var OPPONENT = 1;
	var GF = 2;
}
