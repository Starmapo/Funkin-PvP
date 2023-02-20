package data.song;

import flixel.util.FlxStringUtil;

class TimingPoint extends JsonObject
{
	/**
		The time in milliseconds for when this timing point begins.
	**/
	public var startTime:Float;

	/**
		The BPM during this timing point.
	**/
	public var bpm:Float;

	/**
		The beats per bar during this timing point.

		Timing points are limited to quarter notes only. If you want to use a note value other than quarter notes, you'll have to multiply the BPM. For example, 120 BPM at a 7/8 time signature would be 240 BPM at a 7/4 time signature.
	**/
	public var meter:Int;

	/**
		The amount of milliseconds per beat this timing point takes up.
	**/
	public var beatLength(get, never):Float;

	/**
		The amount of milliseconds per step this timing point takes up.
	**/
	public var stepLength(get, never):Float;

	public function new(data:Dynamic)
	{
		startTime = readFloat(data.startTime, 0, 0, null, 3);
		// Max BPM value is based off of the highest BPM song
		bpm = readFloat(data.bpm, 120, 10, 1015, 3);
		meter = readInt(data.meter, 4, 1, 16);
	}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("startTime", startTime),
			LabelValuePair.weak("bpm", bpm),
			LabelValuePair.weak("meter", meter)
		]);
	}

	function get_beatLength()
	{
		return 60000 / bpm;
	}

	function get_stepLength()
	{
		return 15000 / bpm;
	}
}
