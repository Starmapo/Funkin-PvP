package data;

import flixel.math.FlxMath;
import flixel.util.FlxSort;

class Song extends JsonObject
{
	/**
		The title of the song.
	**/
	public var title:String;

	/**
		The artist of the song.
	**/
	public var artist:String;

	/**
		The source of the song.
	**/
	public var source:String;

	/**
		The name of the instrumental file.
	**/
	public var instFile:String;

	/**
		The name of the vocals file.
	**/
	public var vocalsFile:String;

	/**
		The scroll speed for this map.
	**/
	public var scrollSpeed:Float;

	/**
		The list of timing points for this map.
	**/
	public var timingPoints:Array<TimingPoint> = [];

	/**
		The initial scroll velocity for this map.
	**/
	public var initialScrollVelocity:Float;

	/**
		The list of slider velocities for this map.
	**/
	public var sliderVelocities:Array<SliderVelocity> = [];

	/**
		The list of notes for this map.
	**/
	public var notes:Array<NoteInfo> = [];

	/**
		The length in milliseconds of this map.
	**/
	public var length(get, never):Float;

	public function new(data:Dynamic)
	{
		title = readString(data.title, 'Untitled Song');
		artist = readString(data.artist, 'Unknown Artist');
		source = readString(data.source, 'Unknown Source');
		instFile = readString(data.instFile, 'Inst.ogg');
		vocalsFile = readString(data.vocalsFile, 'Voices.ogg');
		scrollSpeed = readFloat(data.scrollSpeed, 1, 0.01, 10, 2);
		for (t in readArray(data.timingPoints))
		{
			if (t != null)
				timingPoints.push(new TimingPoint(t));
		}
		initialScrollVelocity = readFloat(data.initialScrollVelocity, 1, -100, 100, 2);
		for (s in readArray(data.sliderVelocities))
		{
			if (s != null)
				sliderVelocities.push(new SliderVelocity(s));
		}
		for (n in readArray(data.notes))
		{
			if (n != null)
				notes.push(new NoteInfo(n));
		}
	}

	/**
		Checks if the song file is actually valid.
	**/
	public function isValid()
	{
		if (notes.length == 0)
			return false;

		if (timingPoints.length == 0)
			return false;

		for (note in notes)
		{
			if (note.isLongNote && note.endTime <= note.startTime)
				return false;
		}

		return true;
	}

	/**
		Sorts the notes, timing points and slider velocities.
	**/
	public function sort()
	{
		notes.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
		});
		timingPoints.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
		});
		sliderVelocities.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
		});
	}

	/**
		Gets the average notes per second in the map.
		@param rate The current playback rate.
	**/
	function getAverageNotesPerSecond(rate:Float = 1):Float
	{
		if (notes.length == 0)
			return 0;

		return notes.length / (length / (1000 / rate));
	}

	/**
		Gets the average actions per second in the map. Actions per second is defined as the amount of presses and long note releases the player performs a second.

		Excludes break times.

		@param rate The current playback rate.
	**/
	function getActionsPerSecond(rate:Float = 1):Float
	{
		var actions:Array<Int> = [];
		for (note in notes)
		{
			actions.push(note.startTime);
			if (note.isLongNote)
				actions.push(note.endTime);
		}

		if (actions.length == 0)
			return 0;

		actions.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a, b);
		});

		var length = actions[actions.length - 1] - actions[0];

		for (i in 0...actions.length)
		{
			if (i == 0)
				continue;

			var action = actions[i];
			var previousAction = actions[i - 1];
			var difference = action - previousAction;
			if (difference >= 1000)
				length -= difference;
		}

		return actions.length / (length / (1000 / rate));
	}

	/**
		Finds the most common BPM in the map.
	**/
	function getCommonBPM():Float
	{
		if (timingPoints.length == 0)
			return 0;

		if (notes.length == 0)
			return timingPoints[0].bpm;

		var copiedNotes = notes.copy();
		copiedNotes.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.DESCENDING, a.maxTime, b.maxTime);
		});
		var lastObject = copiedNotes[0];
		var lastTime:Float = lastObject.maxTime;

		var durations:Map<Float, Int> = new Map();
		var i = timingPoints.length - 1;
		while (i >= 0)
		{
			var point = timingPoints[i];
			if (point.startTime > lastTime)
				continue;

			var duration = Std.int(lastTime - (i == 0 ? 0 : point.startTime));
			lastTime = point.startTime;

			if (durations.exists(point.bpm))
				durations[point.bpm] += duration;
			else
				durations[point.bpm] = duration;
		}

		var durationsList:Array<Int> = CoolUtil.getMapArray(durations);

		if (durationsList.length == 0)
			return timingPoints[0].bpm;

		durationsList.sort(function(a, b)
		{
			return FlxSort.byValues(FlxSort.DESCENDING, a, b);
		});

		return durationsList[0];
	}

	/**
		Gets the timing point at a particular point in the map.
		@param time The time to find a timing point at.
	**/
	public function getTimingPointAt(time:Float)
	{
		var index = timingPoints.length - 1;
		while (index >= 0)
		{
			if (timingPoints[index].startTime <= time)
				break;
		}

		if (index == -1)
			return timingPoints[0];

		return timingPoints[index];
	}

	/**
		Gets the scroll velocity at a particular point in the map.
		@param time The time to find a scroll velocity at.
	**/
	public function getScrollVelocityAt(time:Float)
	{
		var index = sliderVelocities.length - 1;
		while (index >= 0)
		{
			if (sliderVelocities[index].startTime <= time)
				break;
		}

		if (index == -1)
			return null;

		return sliderVelocities[index];
	}

	/**
		Finds the length of a timing point.
		@param point The timing point.
	**/
	public function getTimingPointLength(point:TimingPoint):Float
	{
		var index = timingPoints.indexOf(point);
		if (index == -1)
			return 0;

		if (index + 1 < timingPoints.length)
			return timingPoints[index + 1].startTime - timingPoints[index].startTime;

		return length - point.startTime;
	}

	function get_length()
	{
		if (notes.length == 0)
			return 0;

		var max:Int = 0;
		for (note in notes)
		{
			var time = FlxMath.maxInt(note.startTime, note.endTime);
			if (time > max)
				max = time;
		}
		return max;
	}
}

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

	function get_beatLength()
	{
		return 60000 / bpm;
	}

	function get_stepLength()
	{
		return beatLength / 4;
	}
}

class SliderVelocity extends JsonObject
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
		startTime = readFloat(data.startTime, 0, 0, null, 3);
		multiplier = readFloat(data.multiplier, 1, -100, 100, 2);
	}
}

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
		lane = readInt(data.lane, 0, 0, 3);
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

	function get_isLongNote()
	{
		return endTime > 0;
	}

	function get_maxTime()
	{
		return isLongNote ? endTime : startTime;
	}
}
