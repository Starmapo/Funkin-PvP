package data.song;

import flixel.util.FlxStringUtil;

/**
	Note info from a song file.
**/
class NoteInfo extends JsonObject
{
	/**
		The time in milliseconds when the note is supposed to be hit.
	**/
	public var startTime:Int;

	/**
		The lane the note falls in.
	**/
	public var lane:Int;

	/**
		The time in milliseconds when the note ends (if greater than 0, it's considered a hold note).
	**/
	public var endTime:Int;

	/**
		The type of the note. If empty, the default type is used.
	**/
	public var type:String;

	/**
		Extra parameters for the note, if needed.
	**/
	public var params:Array<String>;

	/**
		If the object is a long note (endTime > 0).
	**/
	public var isLongNote(get, never):Bool;

	/**
		Gets the maximum time of this note, returning `endTime` if it's a long note and `startTime` if not.
	**/
	public var maxTime(get, never):Int;

	public function new(data:Dynamic)
	{
		startTime = readInt(data.startTime, 0, 0);
		lane = readInt(data.lane, 0, 0) % 8;
		endTime = readInt(data.endTime, 0, 0);
		type = readString(data.type);
		params = readString(data.params).split(',');
	}

	/**
	 * Gets the timing point this note is in range of.
	 * @param timingPoints 	The list of timing points to use.
	 */
	public function getTimingPoint(timingPoints:Array<TimingPoint>)
	{
		var i = timingPoints.length - 1;
		while (i >= 0)
		{
			if (startTime >= timingPoints[i].startTime)
				return timingPoints[i];
		}

		return timingPoints[0];
	}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("startTime", startTime),
			LabelValuePair.weak("lane", lane),
			LabelValuePair.weak("endTime", endTime),
			LabelValuePair.weak("type", type),
			LabelValuePair.weak("params", params)
		]);
	}

	function get_isLongNote()
	{
		return endTime > 0;
	}

	function get_maxTime()
	{
		return isLongNote ? endTime : startTime;
	}
}
