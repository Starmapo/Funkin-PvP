package backend.structures.song;

import backend.structures.song.CameraFocus.CameraFocusChar;
import backend.structures.song.EventObject.Event;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;
import thx.semver.Version;

using StringTools;

class Song extends JsonObject
{
	public static var CURRENT_VERSION:Version = '1.0.0';
	
	/**
		Loads a song from a path.
	**/
	public static function loadSong(path:String, ?mod:String)
	{
		if (!path.endsWith('.json'))
			path += '.json';
		if (!Paths.exists(path))
			path = Paths.getPath('songs/$path', mod);
			
		if (!Paths.exists(path))
			return null;
			
		var json:Dynamic = Paths.getJson(path, mod);
		if (json == null)
			return null;
			
		var converted = false;
		if (json.song != null)
		{
			var sliderVelocities:Array<Dynamic> = json.sliderVelocities;
			
			json = convertFNFSong(json.song);
			
			if (sliderVelocities != null)
			{
				for (sv in sliderVelocities)
				{
					json.scrollVelocities.push(new ScrollVelocity({
						startTime: sv.startTime,
						multipliers: [sv.multiplier, sv.multiplier]
					}));
				}
			}
			
			converted = true;
		}
		
		var song = new Song(json);
		song.directory = Path.normalize(Path.directory(path));
		var split = song.directory.split('/');
		song.name = split[split.length - 1];
		song.difficultyName = new Path(path).file;
		song.mod = split[1];
		song.sort();
		
		// remove any notes that appear after the instrumental has ended
		// this happens with a VS Garcello chart?
		if (converted)
		{
			var inst = Paths.getSongInst(song);
			if (inst != null && inst.length > 0)
			{
				var i = song.notes.length - 1;
				while (i >= 0)
				{
					var note = song.notes[i];
					if (note.startTime >= inst.length)
						song.notes.remove(note);
					else if (note.endTime >= inst.length)
						note.endTime = inst.length - 1;
					i--;
				}
			}
			
			song.save(path);
		}
		
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
		var pointToSnap = time + (forward ? snapTimePerBeat : -snapTimePerBeat);
		var nearestTick = Math.round((pointToSnap - point.startTime) / snapTimePerBeat) * snapTimePerBeat + point.startTime;
		
		if (Std.int(Math.abs(nearestTick - time)) <= Std.int(snapTimePerBeat))
			return nearestTick;
			
		return (Math.round((pointToSnap - point.startTime) / snapTimePerBeat) + (forward ? -1 : 1)) * snapTimePerBeat + point.startTime;
	}
	
	public static function closestTickToSnap(song:Song, time:Float, snap:Int)
	{
		var point = song.getTimingPointAt(time);
		if (point == null)
			return time;
			
		var timeFwd = getNearestSnapTimeFromTime(song, true, snap, time);
		var timeBwd = getNearestSnapTimeFromTime(song, false, snap, time);
		
		var fwdDiff = Math.abs(time - timeFwd);
		var bwdDiff = Math.abs(time - timeBwd);
		
		if (Math.abs(fwdDiff - bwdDiff) <= 2)
		{
			var snapTimePerBeat = point.beatLength / snap;
			return getNearestSnapTimeFromTime(song, false, snap, time + snapTimePerBeat);
		}
		
		var closestTime = time;
		
		if (bwdDiff < fwdDiff)
			closestTime = timeBwd;
		else if (fwdDiff < bwdDiff)
			closestTime = timeFwd;
			
		return closestTime;
	}
	
	public static function getSongDifficulties(directory:String, ?excludeDifficulty:String)
	{
		var difficulties:Array<String> = [];
		if (Paths.exists(directory) && Paths.isDirectory(directory))
		{
			for (file in Paths.readDirectory(directory))
			{
				var fileName = Path.withoutExtension(file);
				if (file.endsWith('.json') && !file.startsWith('!') && fileName != excludeDifficulty)
					difficulties.push(fileName);
			}
		}
		return difficulties;
	}
	
	public static function getSongLyrics(song:Song)
	{
		var path = getSongLyricsPath(song);
		if (Paths.exists(path))
			return Paths.getContent(path);
		else
			return '';
	}
	
	public static function getSongLyricsPath(song:Song)
	{
		var diffPath = Path.join([song.directory, 'lyrics-' + song.difficultyName.toLowerCase() + '.txt']);
		if (Paths.exists(diffPath))
			return diffPath;
		else
			return Path.join([song.directory, 'lyrics.txt']);
	}
	
	static function convertFNFSong(json:Dynamic)
	{
		var song:Dynamic = {
			title: json.song,
			scrollSpeed: json.speed,
			timingPoints: [
				{
					bpm: json.bpm
				}
			],
			cameraFocuses: [],
			events: [],
			notes: [],
			bf: json.player1,
			opponent: json.player2,
			gf: json.gfVersion != null ? json.gfVersion : json.player3,
			stage: json.stage,
			scrollVelocities: []
		};
		
		if (json.notes != null)
		{
			var curTime:Float = 0;
			var curBPM:Float = json.bpm;
			var curFocus:Null<CameraFocusChar> = null;
			var curNotes:Map<String, Array<Int>> = new Map();
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
					{
						if (note[2] == 'Change Scroll Speed')
						{
							var val:String = note[3];
							var mult = val != null ? Std.parseFloat(val.trim()) : Math.NaN;
							if (Math.isNaN(mult))
								mult = 1;
							json.scrollVelocities.push({
								startTime: note[0],
								multipliers: [mult, mult]
							});
						}
						else
							song.events.push({
								startTime: note[0],
								events: [
									{
										event: note[2],
										params: note[3] + (note[4].length > 0 ? ',' + note[4] : '')
									}
								]
							});
						continue;
					}
					if (noteInfo.lane > 7)
					{
						var type = Math.floor(noteInfo.lane / 8);
						noteInfo.lane %= 8;
						noteInfo.type = 'Type $type';
					}
					if (section.mustHitSection)
					{
						if (noteInfo.lane >= 4)
							noteInfo.lane -= 4;
						else
							noteInfo.lane += 4;
					}
					
					var string = Std.string(noteInfo.startTime);
					if (curNotes.exists(string) && curNotes.get(string).contains(noteInfo.lane))
						continue;
						
					if (noteInfo.type == null)
					{
						if (section.altAnim == true && noteInfo.lane < 4)
							noteInfo.type = 'Alt Animation';
						if (note[3] != null)
						{
							if (note[3] == true)
								noteInfo.type = 'Alt Animation';
							else if (Std.isOfType(note[3], String))
								noteInfo.type = note[3];
							else if (Std.isOfType(note[3], Int) && note[3] != 0)
								noteInfo.type = 'Type ' + note[3];
						}
					}
					song.notes.push(noteInfo);
					
					if (curNotes.exists(string) && !curNotes.get(string).contains(noteInfo.lane))
						curNotes.get(string).push(noteInfo.lane);
					else
						curNotes.set(string, [noteInfo.lane]);
				}
				curTime += section.lengthInSteps * (15000 / curBPM);
			}
		}
		if (json.events != null)
		{
			var events:Array<Array<Dynamic>> = json.events;
			for (event in events)
			{
				var subEvents:Array<Dynamic> = [];
				var subs:Array<Array<String>> = event[1];
				for (sub in subs)
				{
					if (sub[0] == 'Change Scroll Speed')
					{
						var val:String = sub[1];
						var mult = val != null ? Std.parseFloat(val.trim()) : Math.NaN;
						if (Math.isNaN(mult))
							mult = 1;
						json.scrollVelocities.push({
							startTime: sub[0],
							multipliers: [mult, mult]
						});
					}
					else
						subEvents.push({
							event: sub[0],
							params: sub[1] + (sub[2].length > 0 ? ',' + sub[2] : '')
						});
				}
				if (subEvents.length > 0)
					song.events.push({
						startTime: event[0],
						events: subEvents
					});
			}
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
		The name of the instrumental file. Unused for now.
	**/
	// public var instFile:String;
	/**
		The name of the vocals file. Unused for now.
	**/
	// public var vocalsFile:String;
	
	/**
		The list of timing points for this map.
	**/
	public var timingPoints:Array<TimingPoint> = [];
	
	/**
		The initial scroll velocity for this map.
	**/
	public var initialScrollVelocity:Float;
	
	/**
		The list of scroll velocities for this map.
	**/
	public var scrollVelocities:Array<ScrollVelocity> = [];
	
	/**
		The list of camera focuses for this map.
	**/
	public var cameraFocuses:Array<CameraFocus> = [];
	
	/**
		The list of events for this map.
	**/
	public var events:Array<EventObject> = [];
	
	/**
		The list of lyric steps for this map.
	**/
	public var lyricSteps:Array<LyricStep> = [];
	
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
		Stage for this map.
	**/
	public var stage:String;
	
	/**
		The chart version that this map was made with.
	**/
	public var version:Version;
	
	/**
		The directory of this map. Set automatically with `Song.loadSong()`.
	**/
	public var directory:String = '';
	
	/**
		The difficulty name of this map. Set automatically with `Song.loadSong()`.
	**/
	public var difficultyName:String = '';
	
	public var name:String = '';
	public var mod:String = '';
	
	public function new(?data:Dynamic)
	{
		title = readString(data.title, 'Untitled Song');
		artist = readString(data.artist, 'Unknown Artist');
		source = readString(data.source, 'Unknown Source');
		bf = readString(data.bf, 'fnf:bf');
		opponent = readString(data.opponent, 'fnf:dad');
		gf = readString(data.gf, 'fnf:gf');
		stage = readString(data.stage, 'fnf:stage');
		for (t in readArray(data.timingPoints))
		{
			if (t != null)
				timingPoints.push(new TimingPoint(t));
		}
		initialScrollVelocity = readFloat(data.initialScrollVelocity, 1, -100, 100, 2);
		for (s in readArray(data.scrollVelocities))
		{
			if (s != null)
				scrollVelocities.push(new ScrollVelocity(s));
		}
		for (c in readArray(data.cameraFocuses))
		{
			if (c != null)
				cameraFocuses.push(new CameraFocus(c));
		}
		for (e in readArray(data.events))
		{
			if (e != null)
				events.push(new EventObject(e));
		}
		for (l in readArray(data.lyricSteps))
		{
			if (l != null)
				lyricSteps.push(new LyricStep(l));
		}
		for (n in readArray(data.notes))
		{
			if (n != null)
				notes.push(new NoteInfo(n));
		}
		version = readString(data.version, "1.0.0");
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
		Sorts the notes, timing points and scroll velocities.
	**/
	public function sort()
	{
		notes.sort(sortObjects);
		timingPoints.sort(sortObjects);
		scrollVelocities.sort(sortObjects);
		cameraFocuses.sort(sortObjects);
		events.sort(sortObjects);
		lyricSteps.sort(sortObjects);
	}
	
	function sortObjects(a:ITimingObject, b:ITimingObject)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
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
			
		var actions:Array<Float> = [];
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
		var lastTime = lastObject.maxTime;
		
		var durations:Map<String, Float> = [];
		var i = timingPoints.length - 1;
		while (i >= 0)
		{
			var point = timingPoints[i];
			if (point.startTime <= lastTime)
			{
				var duration = lastTime - (i == 0 ? 0 : point.startTime);
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
		var maxDuration:Float = 0;
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
		var index = scrollVelocities.length - 1;
		while (index >= 0)
		{
			if (scrollVelocities[index].startTime <= time)
				break;
				
			index--;
		}
		
		if (index == -1)
			return null;
			
		return scrollVelocities[index];
	}
	
	/**
		Gets the camera focus at a particular point in the map.
		@param time The time to find a camera focus at.
	**/
	public function getCameraFocusAt(time:Float)
	{
		var index = cameraFocuses.length - 1;
		while (index >= 0)
		{
			if (cameraFocuses[index].startTime <= time)
				break;
				
			index--;
		}
		
		if (index == -1)
			return cameraFocuses[0];
			
		return cameraFocuses[index];
	}
	
	/**
		Gets the most recent event object at a particular point in the map.
		@param time The time to find an event object at.
	**/
	public function getEventAt(time:Float)
	{
		var index = events.length - 1;
		while (index >= 0)
		{
			if (events[index].startTime <= time)
				break;
				
			index--;
		}
		
		if (index == -1)
			return events[0];
			
		return events[index];
	}
	
	/**
		Gets the current lyric step at a particular point in the map.
		@param time The time to find a lyric step at.
	**/
	public function getLyricStepAt(time:Float)
	{
		var index = lyricSteps.length - 1;
		while (index >= 0)
		{
			if (lyricSteps[index].startTime <= time)
				break;
				
			index--;
		}
		
		if (index == -1)
			return lyricSteps[0];
			
		return lyricSteps[index];
	}
	
	/**
		Finds the length of a timing point.
		@param point 	The timing point.
		@param inst		The sound object for the instrumental. If the timing point is the last one in the map, it will use this to get its length.
	**/
	public function getTimingPointLength(point:TimingPoint, ?inst:FlxSound):Float
	{
		var index = timingPoints.indexOf(point);
		if (index == -1)
			return 0;
			
		if (index + 1 < timingPoints.length)
			return timingPoints[index + 1].startTime - timingPoints[index].startTime;
			
		if (inst != null)
			return inst.length - point.startTime;
			
		return length - point.startTime;
	}
	
	/**
		Solves the difficulty of the map and returns the data for it.
	**/
	public function solveDifficulty(rightSide:Bool = false, rate:Float = 1)
	{
		return new DifficultyProcessor(this, rightSide, rate);
	}
	
	public function addObject(object:ITimingObject)
	{
		if (Std.isOfType(object, NoteInfo))
			notes.push(cast object);
		else if (Std.isOfType(object, TimingPoint))
			timingPoints.push(cast object);
		else if (Std.isOfType(object, ScrollVelocity))
			scrollVelocities.push(cast object);
		else if (Std.isOfType(object, CameraFocus))
			cameraFocuses.push(cast object);
		else if (Std.isOfType(object, EventObject))
			events.push(cast object);
		else if (Std.isOfType(object, LyricStep))
			lyricSteps.push(cast object);
	}
	
	public function removeObject(object:ITimingObject)
	{
		if (Std.isOfType(object, NoteInfo))
			notes.remove(cast object);
		else if (Std.isOfType(object, TimingPoint))
			timingPoints.remove(cast object);
		else if (Std.isOfType(object, ScrollVelocity))
			scrollVelocities.remove(cast object);
		else if (Std.isOfType(object, CameraFocus))
			cameraFocuses.remove(cast object);
		else if (Std.isOfType(object, EventObject))
			events.remove(cast object);
		else if (Std.isOfType(object, LyricStep))
			lyricSteps.remove(cast object);
	}
	
	/** Clones this song into a new object.**/
	public function deepClone()
	{
		var timingPoints:Array<TimingPoint> = [];
		for (obj in this.timingPoints)
		{
			timingPoints.push(new TimingPoint({
				startTime: obj.startTime,
				bpm: obj.bpm,
				meter: obj.meter
			}));
		}
		
		var scrollVelocities:Array<ScrollVelocity> = [];
		for (obj in this.scrollVelocities)
		{
			scrollVelocities.push(new ScrollVelocity({
				startTime: obj.startTime,
				multipliers: obj.multipliers
			}));
		}
		
		var cameraFocuses:Array<CameraFocus> = [];
		for (obj in this.cameraFocuses)
		{
			cameraFocuses.push(new CameraFocus({
				startTime: obj.startTime,
				char: obj.char
			}));
		}
		
		var events:Array<EventObject> = [];
		for (obj in this.events)
		{
			var subEvents:Array<Event> = [];
			for (sub in obj.events)
				subEvents.push(new Event({
					event: sub.event,
					params: sub.params.join(',')
				}));
				
			events.push(new EventObject({
				startTime: obj.startTime,
				events: subEvents
			}));
		}
		
		var lyricSteps:Array<LyricStep> = [];
		for (obj in this.lyricSteps)
		{
			lyricSteps.push(new LyricStep({
				startTime: obj.startTime
			}));
		}
		
		var notes:Array<NoteInfo> = [];
		for (note in this.notes)
		{
			notes.push(new NoteInfo({
				startTime: note.startTime,
				lane: note.lane,
				endTime: note.endTime,
				type: note.type,
				params: note.params.join(',')
			}));
		}
		
		var data = {
			title: title,
			artist: artist,
			source: source,
			timingPoints: timingPoints,
			initialScrollVelocity: initialScrollVelocity,
			scrollVelocities: scrollVelocities,
			cameraFocuses: cameraFocuses,
			events: events,
			lyricSteps: lyricSteps,
			notes: notes,
			bf: bf,
			opponent: opponent,
			gf: gf,
			stage: stage,
			version: version
		};
		var song = new Song(data);
		song.directory = directory;
		song.difficultyName = difficultyName;
		return song;
	}
	
	public function replaceLongNotesWithRegularNotes()
	{
		for (note in notes)
			note.endTime = 0;
	}
	
	public function applyInverse()
	{
		final MINIMAL_LN_LENGTH = 36;
		final MINIMAL_GAP_LENGTH = 36;
		
		var newNotes:Array<NoteInfo> = [];
		var firstInLane:Array<Bool> = [];
		for (i in 0...8)
			firstInLane[i] = true;
			
		for (i in 0...notes.length)
		{
			var currentNote = notes[i];
			var nextNoteInLane:NoteInfo = null;
			var secondNextNoteInLane:NoteInfo = null;
			for (j in i + 1...notes.length)
			{
				if (notes[j].lane == currentNote.lane)
				{
					if (nextNoteInLane == null)
						nextNoteInLane = notes[j];
					else
					{
						secondNextNoteInLane = notes[j];
						break;
					}
				}
			}
			
			var isFirstInLane = firstInLane[currentNote.lane];
			firstInLane[currentNote.lane] = false;
			
			if (nextNoteInLane == null && isFirstInLane)
			{
				newNotes.push(currentNote);
				continue;
			}
			
			var timeGap:Float = MINIMAL_GAP_LENGTH;
			if (nextNoteInLane != null)
			{
				var timingPoint = getTimingPointAt(nextNoteInLane.startTime);
				var bpm:Float;
				if (Std.int(timingPoint.startTime) == Std.int(nextNoteInLane.startTime))
				{
					var prevTimingPointIndex = timingPoints.length - 1;
					while (prevTimingPointIndex >= 0)
					{
						var x = timingPoints[prevTimingPointIndex];
						if (x.startTime < timingPoint.startTime)
							break;
						prevTimingPointIndex--;
					}
					if (prevTimingPointIndex == -1)
						prevTimingPointIndex = 0;
					bpm = timingPoints[prevTimingPointIndex].bpm;
				}
				else
					bpm = timingPoint.bpm;
					
				timeGap = Math.max(15000 / bpm, MINIMAL_GAP_LENGTH);
			}
			
			if (currentNote.isLongNote)
			{
				if (nextNoteInLane != null)
				{
					currentNote.startTime = currentNote.endTime;
					currentNote.endTime = nextNoteInLane.startTime - timeGap;
					
					if ((secondNextNoteInLane == null) != nextNoteInLane.isLongNote)
						currentNote.endTime = nextNoteInLane.startTime;
						
					if (currentNote.endTime - currentNote.startTime < MINIMAL_LN_LENGTH)
						continue;
				}
			}
			else
			{
				if (nextNoteInLane == null)
					continue;
					
				currentNote.endTime = nextNoteInLane.startTime - timeGap;
				
				if ((secondNextNoteInLane == null) == (nextNoteInLane.endTime == 0))
					currentNote.endTime = nextNoteInLane.startTime;
					
				if (currentNote.endTime - currentNote.startTime < MINIMAL_LN_LENGTH)
					currentNote.endTime = 0;
			}
			
			newNotes.push(currentNote);
		}
		
		newNotes.sort(sortObjects);
		notes = newNotes;
	}
	
	public function mirrorNotes()
	{
		for (note in notes)
		{
			if (note.lane >= 4)
				note.lane = 7 - note.playerLane;
			else
				note.lane = 3 - note.lane;
		}
	}
	
	/**
		Writes this song object into a file.
	**/
	public function save(path:String)
	{
		var timingPoints = [];
		for (obj in this.timingPoints)
		{
			var data:Dynamic = {
				bpm: obj.bpm
			}
			if (obj.startTime != 0)
				data.startTime = obj.startTime;
			if (obj.meter != 4)
				data.meter = obj.meter;
			timingPoints.push(data);
		}
		
		var scrollVelocities = [];
		for (obj in this.scrollVelocities)
		{
			var data:Dynamic = {};
			if (obj.startTime != 0)
				data.startTime = obj.startTime;
			if (obj.multipliers[0] != 1 || obj.multipliers[1] != 1)
				data.multipliers = obj.multipliers;
			scrollVelocities.push(data);
		}
		
		var cameraFocuses = [];
		for (obj in this.cameraFocuses)
		{
			var data:Dynamic = {};
			if (obj.startTime != 0)
				data.startTime = obj.startTime;
			if (obj.char != 0)
				data.char = obj.char;
			cameraFocuses.push(data);
		}
		
		var events = [];
		for (obj in this.events)
		{
			var data:Dynamic = {events: []};
			if (obj.startTime != 0)
				data.startTime = obj.startTime;
			for (sub in obj.events)
				data.events.push({
					event: sub.event,
					params: sub.params.join(',')
				});
			events.push(data);
		}
		
		var lyricSteps = [];
		for (obj in this.lyricSteps)
		{
			var data:Dynamic = {};
			if (obj.startTime != 0)
				data.startTime = obj.startTime;
			lyricSteps.push(data);
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
			timingPoints: timingPoints,
			initialScrollVelocity: initialScrollVelocity,
			scrollVelocities: scrollVelocities,
			cameraFocuses: cameraFocuses,
			events: events,
			lyricSteps: lyricSteps,
			notes: notes,
			bf: bf,
			opponent: opponent,
			gf: gf,
			stage: stage,
			version: version
		};
		File.saveContent(path, Json.stringify(data, "\t"));
	}
	
	public function randomizeLanes()
	{
		var values = [for (i in 0...4) i];
		FlxG.random.shuffle(values);
		
		for (note in notes)
		{
			var add = note.player * 4;
			note.lane = values[note.playerLane] + add;
		}
	}
	
	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("title", title),
			LabelValuePair.weak("timingPoints", timingPoints),
			LabelValuePair.weak("scrollVelocities", scrollVelocities),
			LabelValuePair.weak("notes", notes)
		]);
	}
	
	override function destroy()
	{
		scrollVelocities = FlxDestroyUtil.destroyArray(scrollVelocities);
		events = FlxDestroyUtil.destroyArray(events);
		notes = FlxDestroyUtil.destroyArray(notes);
	}
	
	function get_length():Float
	{
		if (notes.length == 0)
			return 0;
			
		var max:Float = 0;
		for (note in notes)
		{
			var time = Math.max(note.startTime, note.endTime);
			if (time > max)
				max = time;
		}
		return max;
	}
}
