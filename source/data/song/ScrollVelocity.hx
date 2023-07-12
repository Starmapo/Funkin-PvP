package data.song;

import flixel.util.FlxStringUtil;

class ScrollVelocity extends JsonObject implements ITimingObject
{
	/**
		The time in milliseconds for when this scroll velocity begins.
	**/
	public var startTime:Float;
	
	/**
		The velocity multipliers for this scroll velocity.
	**/
	public var multipliers:Array<Float>;
	
	public var linked:Bool;
	
	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0);
		multipliers = readFloatArray(data.multipliers, [1, 1], null, 2, -100, 100, 2);
		linked = readBool(data.linked, true);
	}
	
	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("startTime", startTime),
			LabelValuePair.weak("multipliers", multipliers)
		]);
	}
	
	override function destroy()
	{
		multipliers = null;
	}
}
