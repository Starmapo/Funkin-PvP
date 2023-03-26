package data.song;

import data.song.CameraFocus.CameraFocusChar;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;

class Song extends JsonObject
{
	public static var scrollSpeedMult:Float = 0.32;

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
		song.difficultyName = new Path(path).file;
		song.sort();
		return song;
	}

	public static function createNewSong()
	{
		return new Song({});
	}

	public static function getNearestSnapTimeFromTime(song:Song, forward:Bool, snap:Int, time:Float):Float
	{
		if (song == null)
			return 0;

		var point = song.getTimingPointAt(time);
		if (point == null)
			return 0;

		var snapTimePerBeat = point.beatLength / snap;
		var pointToSnap:Float = time + (forward ? snapTimePerBeat : -snapTimePerBeat);
		var nearestTick = Math.round((pointToSnap - point.startTime) / snapTimePerBeat) * snapTimePerBeat + point.startTime;

		if (Math.abs(nearestTick - time) <= snapTimePerBeat)
			return nearestTick;

		return (Math.round((pointToSnap - point.startTime) / snapTimePerBeat) + (forward ? -1 : 1)) * snapTimePerBeat + point.startTime;
	}

	public static function closestTickToSnap(song:Song, time:Int, snap:Int)
	{
		var point = song.getTimingPointAt(time);
		if (point == null)
			return time;

		var timeFwd = Std.int(Song.getNearestSnapTimeFromTime(song, true, snap, time));
		var timeBwd = Std.int(Song.getNearestSnapTimeFromTime(song, false, snap, time));

		var fwdDiff = Std.int(Math.abs(time - timeFwd));
		var bwdDiff = Std.int(Math.abs(time - timeBwd));

		if (Math.abs(fwdDiff - bwdDiff) <= 2)
		{
			var snapTimePerBeat = point.beatLength / snap;
			return Std.int(getNearestSnapTimeFromTime(song, false, snap, time + snapTimePerBeat));
		}

		var closestTime = time;

		if (bwdDiff < fwdDiff)
			closestTime = timeBwd;
		else if (fwdDiff < bwdDiff)
			closestTime = timeFwd;

		return closestTime;
	}

	static function convertFNFSong(json:Dynamic)
	{
		var song:Dynamic = {
			title: json.song,
			instFile: 'Inst.ogg',
			vocalsFile: json.needsVoices ? 'Voices.ogg' : '',
			scrollSpeed: json.speed,
			timingPoints: [
				{
					bpm: json.bpm
				}
			],
			cameraFocuses: [],
			notes: [],
			bf: json.player1,
			opponent: json.player2,
			gf: json.gfVersion
		};

		var curTime:Float = 0;
		var curBPM:Float = json.bpm;
		var curFocus:Null<CameraFocusChar> = null;
		var curNotes:Map<Int, Array<Int>> = new Map();
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
			var sectionFocus = resolveCameraFocus(section, curTime);
			if (curFocus == null || curFocus != sectionFocus.char)
			{
				song.cameraFocuses.push(sectionFocus);
				curFocus = sectionFocus.char;
			}
			for (i in 0...section.sectionNotes.length)
			{
				var note:Array<Dynamic> = section.sectionNotes[i];
				var noteInfo:Dynamic = {
					startTime: note[0],
					lane: note[1],
					endTime: note[2] > 0 ? note[0] + note[2] : 0,
				};
				if (noteInfo.lane < 0)
					continue;
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

				if (curNotes.exists(noteInfo.startTime) && curNotes.get(noteInfo.startTime).contains(noteInfo.lane))
					continue;

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

				if (curNotes.exists(noteInfo.startTime))
					curNotes.get(noteInfo.startTime).push(noteInfo.lane);
				else
					curNotes.set(noteInfo.startTime, [noteInfo.lane]);
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
		if (section.gfSection == true)
			cameraFocus.char = 2;
		else if (section.mustHitSection == true)
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
		Boyfriend (player 2) character for this map.
	**/
	public var bf:String;

	/**
		Opponent (player 1) character for this map.
	**/
	public var opponent:String;

	/**
		Girlfriend character for this map.
	**/
	public var gf:String;

	/**
		The directory of this map. Set automatically with `Song.loadSong()`.
	**/
	public var directory:String = '';

	/**
		The difficulty name of this map. Set automatically with `Song.loadSong()`.
	**/
	public var difficultyName:String = '';

	public function new(?data:Dynamic)
	{
		title = readString(data.title, 'Untitled Song');
		artist = readString(data.artist, 'Unknown Artist');
		source = readString(data.source, 'Unknown Source');
		instFile = readString(data.instFile, 'Inst.ogg');
		vocalsFile = readString(data.vocalsFile, 'Voices.ogg');
		bf = readString(data.bf, 'bf');
		opponent = readString(data.opponent, 'dad');
		gf = readString(data.gf, 'gf');
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
			if (point.startTime <= lastTime)
			{
				var duration = Std.int(lastTime - (i == 0 ? 0 : point.startTime));
				lastTime = point.startTime;

				var bpm = Std.string(point.bpm);
				if (durations.exists(bpm))
					durations[bpm] += duration;
				else
					durations[bpm] = duration;
			}
			i--;
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

			index--;
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

			index--;
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
	public function solveDifficulty(rightSide:Bool = false, ?mods:Modifiers)
	{
		return new DifficultyProcessor(this, rightSide, mods);
	}

	/**
		Writes this song object into a file.
	**/
	public function save(path:String)
	{
		var timingPoints = [];
		for (point in this.timingPoints)
		{
			var data:Dynamic = {
				bpm: point.bpm
			}
			if (point.startTime != 0)
				data.startTime = point.startTime;
			if (point.meter != 4)
				data.meter = point.meter;
			timingPoints.push(data);
		}

		var sliderVelocities = [];
		for (velocity in this.sliderVelocities)
		{
			var data:Dynamic = {};
			if (velocity.startTime != 0)
				data.startTime = velocity.startTime;
			if (velocity.multiplier != 1)
				data.multiplier = velocity.multiplier;
			sliderVelocities.push(data);
		}

		var cameraFocuses = [];
		for (focus in this.cameraFocuses)
		{
			var data:Dynamic = {};
			if (focus.startTime != 0)
				data.startTime = focus.startTime;
			if (focus.char != 0)
				data.char = focus.char;
			cameraFocuses.push(data);
		}

		var notes = [];
		for (note in this.notes)
		{
			var data:Dynamic = {};
			if (note.startTime != 0)
				data.startTime = note.startTime;
			if (note.lane != 0)
				data.lane = note.lane;
			if (note.endTime != 0)
				data.endTime = note.endTime;
			if (note.type.length > 0)
				data.type = note.type;
			if (note.params.length > 0 && note.params[0].length > 0)
				data.params = note.params.join(',');
			notes.push(data);
		}

		var data = {
			title: title,
			artist: artist,
			source: source,
			instFile: instFile,
			vocalsFile: vocalsFile,
			timingPoints: timingPoints,
			initialScrollVelocity: initialScrollVelocity,
			sliderVelocities: sliderVelocities,
			cameraFocuses: cameraFocuses,
			notes: notes,
			bf: bf,
			opponent: opponent,
			gf: gf
		};
		File.saveContent(path, Json.stringify(data, "\t"));
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
