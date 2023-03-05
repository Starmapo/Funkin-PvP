package data.song;

import data.song.CameraFocus.CameraFocusChar;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import haxe.io.Path;

class Song extends JsonObject
{
	/**
		Loads a song from a path.
	**/
	public static function loadSong(path:String, ?mod:String)
	{
		if (!Paths.exists(path))
			return null;

		var json:Dynamic = Paths.getJson(path, mod);

		if (json.song != null)
			json = convertFNFSong(json.song);

		var song = new Song(json);
		song.directory = Path.directory(path);
		return song;
	}

	static function convertFNFSong(json:Dynamic)
	{
		var song:Dynamic = {
			title: json.song,
			vocalsFile: json.needsVoices ? 'Voices.ogg' : '',
			scrollSpeed: json.speed,
			timingPoints: [
				{
					bpm: json.bpm
				}
			],
			cameraFocuses: [resolveCameraFocus(json.notes[0])],
			notes: [],
			bf: json.player1,
			opponent: json.player2,
			gf: json.gfVersion
		};

		var curTime:Float = 0;
		var curBPM:Float = json.bpm;
		var curFocus:CameraFocusChar = song.cameraFocuses[0].char;
		for (i in 0...json.notes.length)
		{
			var section = json.notes[i];
			if (section.changeBPM == true)
			{
				song.timingPoints.push({
					startTime: curTime,
					bpm: section.bpm
				});
				curBPM = section.bpm;
			}
			if (i > 0)
			{
				var sectionFocus = resolveCameraFocus(section, curTime);
				if (curFocus != sectionFocus.char)
				{
					song.cameraFocuses.push(sectionFocus);
				}
			}
			for (i in 0...section.sectionNotes.length)
			{
				var note:Array<Dynamic> = section.sectionNotes[i];
				var noteInfo = {
					startTime: note[0],
					lane: note[1],
					endTime: note[2] > 0 ? note[0] + note[2] : 0,
					type: ''
				};
				if (section.mustHitSection)
				{
					if (noteInfo.lane >= 4)
					{
						noteInfo.lane -= 4;
					}
					else
					{
						noteInfo.lane += 4;
					}
				}
				if (section.altAnim == true)
				{
					noteInfo.type = 'Alt Animation';
				}
				if (note[3] != null)
				{
					if (note[3] == true)
					{
						noteInfo.type = 'Alt Animation';
					}
					else if (Std.isOfType(note[3], String))
					{
						noteInfo.type = note[3];
					};
				}
				song.notes.push(noteInfo);
			}
			curTime += section.lengthInSteps * (15000 / curBPM);
		}
		return song;
	}

	static function resolveCameraFocus(section:Dynamic, startTime:Float = 0)
	{
		var cameraFocus = {
			startTime: startTime,
			char: 0
		};
		if (section.gfSection != null && section.gfSection)
			cameraFocus.char = 2;
		else if (!section.mustHitSection)
			cameraFocus.char = 1;
		return cameraFocus;
	}

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
		The list of camera focuses for this map.
	**/
	public var cameraFocuses:Array<CameraFocus> = [];

	/**
		The list of notes for this map.
	**/
	public var notes:Array<NoteInfo> = [];

	/**
		The length in milliseconds of this map.
	**/
	public var length(get, never):Float;

	/**
		Boyfriend character for this map.
	**/
	public var bf:String;

	/**
		The opponent for this map.
	**/
	public var opponent:String;

	/**
		Girlfriend character for this map.
	**/
	public var gf:String;

	/**
		The directory of this map.
	**/
	public var directory:String;

	public function new(data:Dynamic)
	{
		title = readString(data.title, 'Untitled Song');
		artist = readString(data.artist, 'Unknown Artist');
		source = readString(data.source, 'Unknown Source');
		instFile = readString(data.instFile, 'Inst.ogg');
		vocalsFile = readString(data.vocalsFile, 'Voices.ogg');
		scrollSpeed = readFloat(data.scrollSpeed, 1, 0.01, 10, 2);
		bf = readString(data.bf, 'fnf:bf');
		opponent = readString(data.opponent, 'fnf:dad');
		gf = readString(data.gf, 'fnf:gf');
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
		for (c in readArray(data.cameraFocuses))
		{
			if (c != null)
				cameraFocuses.push(new CameraFocus(c));
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
	public function getAverageNotesPerSecond(rate:Float = 1):Float
	{
		if (notes.length == 0)
			return 0;
		if (length == 0)
			return notes.length;

		return notes.length / (length / (1000 / rate));
	}

	/**
		Gets the average actions per second in the map. Actions per second is defined as the amount of presses and long note releases the player performs a second.

		Excludes break times.

		@param rate The current playback rate.
	**/
	public function getActionsPerSecond(rate:Float = 1):Float
	{
		if (notes.length == 0)
			return 0;

		var actions:Array<Int> = [];
		for (note in notes)
		{
			actions.push(note.startTime);
			if (note.isLongNote)
				actions.push(note.endTime);
		}

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

		if (length == 0)
			return actions.length;

		return actions.length / (length / (1000 / rate));
	}

	/**
		Finds the most common BPM in the map.
	**/
	public function getCommonBPM():Float
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

		// for whatever reason, float maps aren't supported, so I have to make it a string map
		var durations:Map<String, Int> = [];
		var i = timingPoints.length - 1;
		while (i >= 0)
		{
			var point = timingPoints[i];
			if (point.startTime > lastTime)
				continue;

			var duration = Std.int(lastTime - (i == 0 ? 0 : point.startTime));
			lastTime = point.startTime;

			var bpm = Std.string(point.bpm);
			if (durations.exists(bpm))
				durations[bpm] += duration;
			else
				durations[bpm] = duration;
		}

		var commonBPM:Float = 0;
		var maxDuration:Int = 0;
		for (bpm => duration in durations)
		{
			if (duration > maxDuration)
			{
				commonBPM = Std.parseFloat(bpm);
				maxDuration = duration;
			}
		}

		return commonBPM;
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

	/**
		Solves the difficulty of the map and returns the data for it.
	**/
	public function solveDifficulty(mods:Modifiers)
	{
		return new DifficultyProcessor(this, mods);
	}

	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("title", title),
			LabelValuePair.weak("timingPoints", timingPoints),
			LabelValuePair.weak("sliderVelocities", sliderVelocities),
			LabelValuePair.weak("notes", notes)
		]);
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
