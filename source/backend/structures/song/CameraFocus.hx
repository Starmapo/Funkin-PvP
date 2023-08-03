package backend.structures.song;

import flixel.util.FlxStringUtil;

/**
	An object to switch the camera focus in a song.
**/
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

/**
	Characters you can focus on. Can be passed to and from `Int`.
**/
enum abstract CameraFocusChar(Int) from Int to Int
{
	/**
		Focuses on the opponent (player 1 / left side).
	**/
	var OPPONENT = 0;
	
	/**
		Focuses on Boyfriend (player 2 / right side).
	**/
	var BF = 1;
	
	/**
		Focuses on Girlfriend.
	**/
	var GF = 2;
}
