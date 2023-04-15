package data.song;

import flixel.util.FlxStringUtil;

class SliderVelocity extends JsonObject implements ITimingObject
{
	/**
		The time in milliseconds for when this slider velocity begins.
	**/
	public var startTime:Float;

	/**
		The velocity multiplier for this slider velocity.
	**/
	public var multiplier:Float;

	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0);
		multiplier = readFloat(data.multiplier, 1, -100, 100, 2);
	}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("startTime", startTime),
			LabelValuePair.weak("multiplier", multiplier)
		]);
	}
}
