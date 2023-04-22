package util.editors.song;

import data.song.CameraFocus;
import data.song.EventObject;
import data.song.ITimingObject;
import data.song.LyricStep;
import data.song.NoteInfo;
import data.song.ScrollVelocity;
import data.song.Song;
import data.song.TimingPoint;
import flixel.math.FlxMath;
import states.editors.SongEditorState;
import util.editors.actions.ActionManager;
import util.editors.actions.IAction;

using StringTools;

class SongEditorActionManager extends ActionManager
{
	public static inline var ADD_OBJECT:String = 'add-object';
	public static inline var REMOVE_OBJECT:String = 'remove-object';
	public static inline var ADD_OBJECT_BATCH:String = 'add-object-batch';
	public static inline var REMOVE_OBJECT_BATCH:String = 'remove-object-batch';
	public static inline var RESIZE_LONG_NOTE:String = 'resize-long-note';
	public static inline var CHANGE_NOTE_TYPE:String = 'change-note-type';
	public static inline var CHANGE_NOTE_PARAMS:String = 'change-note-params';
	public static inline var MOVE_OBJECTS:String = 'move-objects';
	public static inline var RESNAP_OBJECTS:String = 'resnap-objects';
	public static inline var FLIP_NOTES:String = 'flip-notes';
	public static inline var APPLY_MODIFIER:String = 'apply-modifier';
	public static inline var CHANGE_TIMING_POINT_TIME:String = 'change-timing-point-time';
	public static inline var CHANGE_TIMING_POINT_BPM:String = 'change-timing-point-bpm';
	public static inline var CHANGE_TIMING_POINT_METER:String = 'change-timing-point-meter';
	public static inline var CHANGE_SV_MULTIPLIER:String = 'change-sv-multiplier';
	public static inline var CHANGE_SV_MULTIPLIERS:String = 'change-sv-multipliers';
	public static inline var CHANGE_SV_LINKED:String = 'change-sv-linked';
	public static inline var CHANGE_CAMERA_FOCUS_CHAR:String = 'change-camera-focus-char';
	public static inline var CHANGE_EVENT:String = 'change-event';
	public static inline var CHANGE_EVENT_PARAMS:String = 'change-event-params';
	public static inline var ADD_EVENT:String = 'add-event';
	public static inline var REMOVE_EVENT:String = 'remove-event';
	public static inline var CHANGE_TITLE:String = 'change-title';
	public static inline var CHANGE_ARTIST:String = 'change-artist';
	public static inline var CHANGE_SOURCE:String = 'change-source';
	public static inline var CHANGE_DIFFICULTY_NAME:String = 'change-difficulty-name';
	public static inline var CHANGE_OPPONENT:String = 'change-opponent';
	public static inline var CHANGE_BF:String = 'change-bf';
	public static inline var CHANGE_GF:String = 'change-gf';
	public static inline var CHANGE_STAGE:String = 'change-stage';
	public static inline var CHANGE_INITIAL_SV:String = 'change-initial-sv';

	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}

	public function addNote(lane:Int, startTime:Float, endTime:Float = 0, type:String = '', params:String = '')
	{
		var note = new NoteInfo({
			startTime: startTime,
			lane: lane,
			endTime: endTime,
			type: type,
			params: params
		});
		perform(new ActionAddObject(state, note));
		return note;
	}

	public function addTimingPoint(startTime:Float, bpm:Float, meter:Int = 4)
	{
		var obj = new TimingPoint({
			startTime: startTime,
			bpm: bpm,
			meter: meter
		});
		perform(new ActionAddObject(state, obj));
		return obj;
	}

	public function addScrollVelocity(startTime:Float, multipliers:Array<Float>, linked:Bool = true)
	{
		var obj = new ScrollVelocity({
			startTime: startTime,
			multipliers: multipliers,
			linked: linked
		});
		perform(new ActionAddObject(state, obj));
		return obj;
	}

	public function addCamFocus(startTime:Float, char:CameraFocusChar = OPPONENT)
	{
		var obj = new CameraFocus({
			startTime: startTime,
			char: char
		});
		perform(new ActionAddObject(state, obj));
		return obj;
	}

	public function addEvent(startTime:Float, event:String, params:String)
	{
		var obj = new EventObject({
			startTime: startTime,
			events: [
				{
					event: event,
					params: params
				}
			]
		});
		perform(new ActionAddObject(state, obj));
		return obj;
	}

	public function addLyricStep(startTime:Float)
	{
		var obj = new LyricStep({
			startTime: startTime
		});
		perform(new ActionAddObject(state, obj));
		return obj;
	}
}

class ActionAddObject implements IAction
{
	public var type:String = SongEditorActionManager.ADD_OBJECT;

	var state:SongEditorState;
	var object:ITimingObject;

	public function new(state:SongEditorState, object:ITimingObject)
	{
		this.state = state;
		this.object = object;
	}

	public function perform()
	{
		state.song.addObject(object);
		state.song.sort();
		state.actionManager.triggerEvent(type, {
			object: object
		});
	}

	public function undo()
	{
		new ActionRemoveObject(state, object).perform();
	}
}

class ActionRemoveObject implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_OBJECT;

	var state:SongEditorState;
	var object:ITimingObject;

	public function new(state:SongEditorState, object:ITimingObject)
	{
		this.state = state;
		this.object = object;
	}

	public function perform()
	{
		state.song.removeObject(object);
		state.selectedObjects.remove(object);
		state.actionManager.triggerEvent(type, {
			object: object
		});
	}

	public function undo()
	{
		new ActionAddObject(state, object).perform();
	}
}

class ActionAddObjectBatch implements IAction
{
	public var type:String = SongEditorActionManager.ADD_OBJECT_BATCH;

	var state:SongEditorState;
	var objects:Array<ITimingObject>;

	public function new(state:SongEditorState, objects:Array<ITimingObject>)
	{
		this.state = state;
		this.objects = objects;
	}

	public function perform()
	{
		for (obj in objects)
			state.song.addObject(obj);
		state.song.sort();
		state.actionManager.triggerEvent(type, {objects: objects});
	}

	public function undo()
	{
		new ActionRemoveObjectBatch(state, objects).perform();
	}
}

class ActionRemoveObjectBatch implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_OBJECT_BATCH;

	var state:SongEditorState;
	var objects:Array<ITimingObject>;

	public function new(state:SongEditorState, objects:Array<ITimingObject>)
	{
		this.state = state;
		this.objects = objects;
	}

	public function perform()
	{
		for (obj in objects)
		{
			state.song.removeObject(obj);
			state.selectedObjects.remove(obj);
		}
		state.song.sort();
		state.actionManager.triggerEvent(type, {objects: objects});
	}

	public function undo()
	{
		new ActionAddObjectBatch(state, objects).perform();
	}
}

class ActionResizeLongNote implements IAction
{
	public var type:String = SongEditorActionManager.RESIZE_LONG_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;
	var originalTime:Float;
	var newTime:Float;

	public function new(state:SongEditorState, note:NoteInfo, originalTime:Float, newTime:Float)
	{
		this.state = state;
		this.note = note;
		this.originalTime = originalTime;
		this.newTime = newTime;
	}

	public function perform()
	{
		note.endTime = newTime;
		state.actionManager.triggerEvent(type, {note: note, originalTime: originalTime, newTime: newTime});
	}

	public function undo()
	{
		new ActionResizeLongNote(state, note, newTime, originalTime).perform();
	}
}

class ActionChangeNoteType implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_NOTE_TYPE;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;
	var noteType:String;
	var lastTypes:Map<NoteInfo, String> = new Map();

	public function new(state:SongEditorState, notes:Array<NoteInfo>, noteType:String)
	{
		this.state = state;
		this.notes = notes;
		this.noteType = noteType;
	}

	public function perform()
	{
		for (note in notes)
		{
			lastTypes.set(note, note.type);
			note.type = noteType;
		}

		state.actionManager.triggerEvent(type, {notes: notes, noteType: noteType});
	}

	public function undo()
	{
		for (note in notes)
			note.type = lastTypes.get(note);
		lastTypes.clear();

		state.actionManager.triggerEvent(type, {notes: notes, noteType: noteType});
	}
}

class ActionChangeNoteParams implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_NOTE_PARAMS;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;
	var params:Array<String>;
	var lastParams:Map<NoteInfo, Array<String>> = new Map();

	public function new(state:SongEditorState, notes:Array<NoteInfo>, params:String)
	{
		this.state = state;
		this.notes = notes;
		this.params = params.trim().split(',');
	}

	public function perform()
	{
		for (note in notes)
		{
			lastParams.set(note, note.params.copy());
			note.params = params.copy();
		}

		state.actionManager.triggerEvent(type, {notes: notes, params: params});
	}

	public function undo()
	{
		for (note in notes)
			note.params = lastParams.get(note);
		lastParams.clear();

		state.actionManager.triggerEvent(type, {notes: notes, params: params});
	}
}

class ActionMoveObjects implements IAction
{
	public var type:String = SongEditorActionManager.MOVE_OBJECTS;

	var state:SongEditorState;
	var objects:Array<ITimingObject>;
	var laneOffset:Int;
	var dragOffset:Float;
	var shouldPerform:Bool;

	public function new(state:SongEditorState, ?objects:Array<ITimingObject>, laneOffset:Int, dragOffset:Float, shouldPerform:Bool = true)
	{
		this.state = state;
		this.objects = objects;
		this.laneOffset = laneOffset;
		this.dragOffset = dragOffset;
		this.shouldPerform = shouldPerform;
	}

	public function perform()
	{
		if (shouldPerform)
		{
			for (obj in objects)
			{
				obj.startTime += dragOffset;
				trace(obj.startTime);
				if (Std.isOfType(obj, NoteInfo))
				{
					var obj:NoteInfo = cast obj;
					if (obj.isLongNote)
						obj.endTime += dragOffset;
					obj.lane += laneOffset;
				}
			}
		}

		state.actionManager.triggerEvent(type, {objects: objects});
	}

	public function undo()
	{
		new ActionMoveObjects(state, objects, -laneOffset, -dragOffset).perform();
		shouldPerform = true;
	}
}

class ActionResnapObjects implements IAction
{
	public var type:String = SongEditorActionManager.RESNAP_OBJECTS;

	var state:SongEditorState;
	var snaps:Array<Int>;
	var objects:Array<ITimingObject>;
	var noteTimeAdjustments:Map<NoteInfo, NoteAdjustment> = new Map();
	var timeAdjustments:Map<ITimingObject, TimingAdjustment> = new Map();

	public function new(state:SongEditorState, snaps:Array<Int>, ?objects:Array<ITimingObject>)
	{
		this.state = state;
		this.snaps = snaps;
		this.objects = objects;
	}

	public function perform()
	{
		var resnapCount = 0;
		if (objects != null)
		{
			for (obj in objects)
			{
				if (Std.isOfType(obj, NoteInfo))
				{
					var obj:NoteInfo = cast obj;
					var originalStartTime = obj.startTime;
					var originalEndTime = obj.endTime;
					obj.startTime = closestTickOverall(obj.startTime);
					if (obj.isLongNote)
						obj.endTime = closestTickOverall(obj.endTime);

					var adjustment = new NoteAdjustment(originalStartTime, originalEndTime, obj);
					if (adjustment.wasMoved)
					{
						noteTimeAdjustments.set(obj, adjustment);
						resnapCount++;
					}
				}
				else
				{
					var originalStartTime = obj.startTime;
					obj.startTime = closestTickOverall(obj.startTime);

					var adjustment = new TimingAdjustment(originalStartTime, obj);
					if (adjustment.wasMoved)
					{
						timeAdjustments.set(obj, adjustment);
						resnapCount++;
					}
				}
			}
		}

		if (resnapCount > 0)
		{
			state.actionManager.triggerEvent(type, {
				snaps: snaps,
				objects: objects
			});
		}
	}

	public function undo()
	{
		for (obj => adjustment in noteTimeAdjustments)
		{
			obj.startTime = adjustment.originalStartTime;
			obj.endTime = adjustment.originalEndTime;
		}
		for (obj => adjustment in timeAdjustments)
			obj.startTime = adjustment.originalStartTime;

		state.actionManager.triggerEvent(type, {
			snaps: snaps,
			objects: objects
		});

		noteTimeAdjustments.clear();
		timeAdjustments.clear();
	}

	function closestTickOverall(time:Float)
	{
		var closestTime:Float = FlxMath.MAX_VALUE_FLOAT;
		for (snap in snaps)
		{
			var newTime = Song.closestTickToSnap(state.song, time, snap);
			if (Math.abs(time - newTime) < Math.abs(time - closestTime))
				closestTime = newTime;
		}
		return closestTime;
	}
}

class ActionFlipNotes implements IAction
{
	public var type:String = SongEditorActionManager.FLIP_NOTES;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;
	var fullFlip:Bool;

	public function new(state:SongEditorState, notes:Array<NoteInfo>, fullFlip:Bool)
	{
		this.state = state;
		this.notes = notes;
		this.fullFlip = fullFlip;
	}

	public function perform()
	{
		for (note in notes)
		{
			if (fullFlip)
				note.lane = 7 - note.lane;
			else
			{
				if (note.lane >= 4)
					note.lane = 7 - note.playerLane;
				else
					note.lane = 3 - note.lane;
			}
		}

		state.actionManager.triggerEvent(type, {
			notes: notes
		});
	}

	public function undo()
	{
		perform();
	}
}

class ActionApplyModifier implements IAction
{
	public var type:String = SongEditorActionManager.APPLY_MODIFIER;

	var state:SongEditorState;
	var modifier:Modifier;
	var originalNotes:Array<NoteInfo> = [];

	public function new(state:SongEditorState, modifier:Modifier)
	{
		this.state = state;
		this.modifier = modifier;
	}

	public function perform()
	{
		for (note in state.song.notes)
			originalNotes.push(new NoteInfo({
				startTime: note.startTime,
				lane: note.lane,
				endTime: note.endTime,
				type: note.type,
				params: note.params.join(',')
			}));

		switch (modifier)
		{
			case MIRROR:
				state.song.mirrorNotes();
			case NO_LONG_NOTES:
				state.song.replaceLongNotesWithRegularNotes();
			case FULL_LONG_NOTES:
				state.song.replaceLongNotesWithRegularNotes();
				state.song.applyInverse();
			case INVERSE:
				state.song.applyInverse();
		}

		state.actionManager.triggerEvent(type, {modifier: modifier});
	}

	public function undo()
	{
		state.song.notes = originalNotes.copy();
		originalNotes.resize(0);

		state.actionManager.triggerEvent(type, {modifier: modifier});
	}
}

class ActionChangeTimingPointTime implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_TIMING_POINT_TIME;

	var state:SongEditorState;
	var timingPoints:Array<TimingPoint>;
	var time:Float;
	var lastTimes:Map<TimingPoint, Float> = new Map();

	public function new(state:SongEditorState, timingPoints:Array<TimingPoint>, time:Float)
	{
		this.state = state;
		this.timingPoints = timingPoints;
		this.time = time;
	}

	public function perform()
	{
		for (obj in timingPoints)
		{
			lastTimes.set(obj, obj.startTime);
			obj.startTime = time;
		}

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, time: time});
	}

	public function undo()
	{
		for (obj in timingPoints)
			obj.startTime = lastTimes.get(obj);
		lastTimes.clear();

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, time: time});
	}
}

class ActionChangeTimingPointBPM implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_TIMING_POINT_BPM;

	var state:SongEditorState;
	var timingPoints:Array<TimingPoint>;
	var bpm:Float;
	var lastBPMs:Map<TimingPoint, Float> = new Map();

	public function new(state:SongEditorState, timingPoints:Array<TimingPoint>, bpm:Float)
	{
		this.state = state;
		this.timingPoints = timingPoints;
		this.bpm = bpm;
	}

	public function perform()
	{
		for (obj in timingPoints)
		{
			lastBPMs.set(obj, obj.bpm);
			obj.bpm = bpm;
		}

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, bpm: bpm});
	}

	public function undo()
	{
		for (obj in timingPoints)
			obj.bpm = lastBPMs.get(obj);
		lastBPMs.clear();

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, bpm: bpm});
	}
}

class ActionChangeTimingPointMeter implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_TIMING_POINT_METER;

	var state:SongEditorState;
	var timingPoints:Array<TimingPoint>;
	var meter:Int;
	var lastMeters:Map<TimingPoint, Int> = new Map();

	public function new(state:SongEditorState, timingPoints:Array<TimingPoint>, meter:Int)
	{
		this.state = state;
		this.timingPoints = timingPoints;
		this.meter = meter;
	}

	public function perform()
	{
		for (obj in timingPoints)
		{
			lastMeters.set(obj, obj.meter);
			obj.meter = meter;
		}

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, meter: meter});
	}

	public function undo()
	{
		for (obj in timingPoints)
			obj.meter = lastMeters.get(obj);
		lastMeters.clear();

		state.actionManager.triggerEvent(type, {timingPoints: timingPoints, meter: meter});
	}
}

class ActionChangeSVMultiplier implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_SV_MULTIPLIER;

	var state:SongEditorState;
	var scrollVelocities:Array<ScrollVelocity>;
	var player:Int;
	var multiplier:Float;
	var lastMultipliers:Map<ScrollVelocity, Float> = new Map();

	public function new(state:SongEditorState, scrollVelocities:Array<ScrollVelocity>, player:Int, multiplier:Float)
	{
		this.state = state;
		this.scrollVelocities = scrollVelocities;
		this.player = player;
		this.multiplier = multiplier;
	}

	public function perform()
	{
		for (obj in scrollVelocities)
		{
			lastMultipliers.set(obj, obj.multipliers[player]);
			obj.multipliers[player] = multiplier;
		}

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, player: player, multiplier: multiplier});
	}

	public function undo()
	{
		for (obj in scrollVelocities)
			obj.multipliers[player] = lastMultipliers.get(obj);
		lastMultipliers.clear();

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, player: player, multiplier: multiplier});
	}
}

class ActionChangeSVMultipliers implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_SV_MULTIPLIERS;

	var state:SongEditorState;
	var scrollVelocities:Array<ScrollVelocity>;
	var multipliers:Array<Float>;
	var lastMultipliers:Map<ScrollVelocity, Array<Float>> = new Map();

	public function new(state:SongEditorState, scrollVelocities:Array<ScrollVelocity>, multipliers:Array<Float>)
	{
		this.state = state;
		this.scrollVelocities = scrollVelocities;
		this.multipliers = multipliers;
	}

	public function perform()
	{
		for (obj in scrollVelocities)
		{
			lastMultipliers.set(obj, obj.multipliers.copy());
			obj.multipliers = multipliers.copy();
		}

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, multipliers: multipliers});
	}

	public function undo()
	{
		for (obj in scrollVelocities)
			obj.multipliers = lastMultipliers.get(obj);
		lastMultipliers.clear();

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, multipliers: multipliers});
	}
}

class ActionChangeSVLinked implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_SV_LINKED;

	var state:SongEditorState;
	var scrollVelocities:Array<ScrollVelocity>;
	var linked:Bool;
	var lastLinked:Map<ScrollVelocity, Bool> = new Map();

	public function new(state:SongEditorState, scrollVelocities:Array<ScrollVelocity>, linked:Bool)
	{
		this.state = state;
		this.scrollVelocities = scrollVelocities;
		this.linked = linked;
	}

	public function perform()
	{
		for (obj in scrollVelocities)
		{
			lastLinked.set(obj, obj.linked);
			obj.linked = linked;
		}

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, linked: linked});
	}

	public function undo()
	{
		for (obj in scrollVelocities)
			obj.linked = lastLinked.get(obj);
		lastLinked.clear();

		state.actionManager.triggerEvent(type, {scrollVelocities: scrollVelocities, linked: linked});
	}
}

class ActionChangeCameraFocusChar implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_CAMERA_FOCUS_CHAR;

	var state:SongEditorState;
	var cameraFocuses:Array<CameraFocus>;
	var char:CameraFocusChar;
	var lastChars:Map<CameraFocus, CameraFocusChar> = new Map();

	public function new(state:SongEditorState, cameraFocuses:Array<CameraFocus>, char:CameraFocusChar)
	{
		this.state = state;
		this.cameraFocuses = cameraFocuses;
		this.char = char;
	}

	public function perform()
	{
		for (obj in cameraFocuses)
		{
			lastChars.set(obj, obj.char);
			obj.char = char;
		}

		state.actionManager.triggerEvent(type, {cameraFocuses: cameraFocuses, char: char});
	}

	public function undo()
	{
		for (obj in cameraFocuses)
			obj.char = lastChars.get(obj);
		lastChars.clear();

		state.actionManager.triggerEvent(type, {cameraFocuses: cameraFocuses, char: char});
	}
}

class ActionChangeEvent implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_EVENT;

	var state:SongEditorState;
	var eventInfo:Event;
	var event:String;
	var lastEvent:String;

	public function new(state:SongEditorState, eventInfo:Event, event:String)
	{
		this.state = state;
		this.eventInfo = eventInfo;
		this.event = event;
	}

	public function perform()
	{
		lastEvent = eventInfo.event;
		eventInfo.event = event;

		state.actionManager.triggerEvent(type, {eventInfo: eventInfo, event: event});
	}

	public function undo()
	{
		eventInfo.event = lastEvent;

		state.actionManager.triggerEvent(type, {eventInfo: eventInfo, event: event});
	}
}

class ActionChangeEventParams implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_EVENT_PARAMS;

	var state:SongEditorState;
	var eventInfo:Event;
	var params:String;
	var lastParams:String;

	public function new(state:SongEditorState, eventInfo:Event, params:String)
	{
		this.state = state;
		this.eventInfo = eventInfo;
		this.params = params;
	}

	public function perform()
	{
		lastParams = eventInfo.params.join(',');
		eventInfo.params = params.split(',');

		state.actionManager.triggerEvent(type, {eventInfo: eventInfo, params: params});
	}

	public function undo()
	{
		eventInfo.params = lastParams.split(',');

		state.actionManager.triggerEvent(type, {eventInfo: eventInfo, evparamsent: params});
	}
}

class ActionAddEvent implements IAction
{
	public var type:String = SongEditorActionManager.ADD_EVENT;

	var state:SongEditorState;
	var eventObject:EventObject;
	var event:Event;

	public function new(state:SongEditorState, eventObject:EventObject, event:Event)
	{
		this.state = state;
		this.eventObject = eventObject;
		this.event = event;
	}

	public function perform()
	{
		eventObject.events.push(event);

		state.actionManager.triggerEvent(type, {eventObject: eventObject, event: event});
	}

	public function undo()
	{
		new ActionRemoveEvent(state, eventObject, event).perform();
	}
}

class ActionRemoveEvent implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_EVENT;

	var state:SongEditorState;
	var eventObject:EventObject;
	var event:Event;

	public function new(state:SongEditorState, eventObject:EventObject, event:Event)
	{
		this.state = state;
		this.eventObject = eventObject;
		this.event = event;
	}

	public function perform()
	{
		eventObject.events.remove(event);

		state.actionManager.triggerEvent(type, {eventObject: eventObject, event: event});
	}

	public function undo()
	{
		new ActionAddEvent(state, eventObject, event).perform();
	}
}

class ActionChangeTitle implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_TITLE;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.title = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.title = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {title: state.song.title});
	}
}

class ActionChangeArtist implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_ARTIST;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.artist = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.artist = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {artist: state.song.artist});
	}
}

class ActionChangeSource implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_SOURCE;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.source = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.source = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {source: state.song.source});
	}
}

class ActionChangeDifficultyName implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_DIFFICULTY_NAME;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.difficultyName = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.difficultyName = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {difficultyName: state.song.difficultyName});
	}
}

class ActionChangeOpponent implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_OPPONENT;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.opponent = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.opponent = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {opponent: state.song.opponent});
	}
}

class ActionChangeBF implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_BF;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.bf = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.bf = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {bf: state.song.bf});
	}
}

class ActionChangeGF implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_GF;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.gf = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.gf = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {gf: state.song.gf});
	}
}

class ActionChangeStage implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_STAGE;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.stage = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.stage = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {stage: state.song.stage});
	}
}

class ActionChangeInitialSV implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_INITIAL_SV;

	var state:SongEditorState;
	var value:Float;
	var lastValue:Float;

	public function new(state:SongEditorState, value:Float, lastValue:Float)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.initialScrollVelocity = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.initialScrollVelocity = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {initialScrollVelocity: state.song.initialScrollVelocity});
	}
}

class TimingAdjustment
{
	public var originalStartTime:Float;
	public var newStartTime:Float;
	public var wasMoved(get, never):Bool;

	public function new(originalStartTime:Float, info:ITimingObject)
	{
		this.originalStartTime = originalStartTime;
		newStartTime = info.startTime;
	}

	function get_wasMoved()
	{
		return originalStartTime != newStartTime;
	}
}

class NoteAdjustment extends TimingAdjustment
{
	public var originalEndTime:Float;
	public var newEndTime:Float;
	public var startTimeWasChanged(get, never):Bool;
	public var endTimeWasChanged(get, never):Bool;

	public function new(originalStartTime:Float, originalEndTime:Float, info:NoteInfo)
	{
		super(originalStartTime, info);
		this.originalEndTime = originalEndTime;
		newEndTime = info.endTime;
	}

	function get_startTimeWasChanged()
	{
		return originalStartTime != newStartTime;
	}

	function get_endTimeWasChanged()
	{
		return originalEndTime != newEndTime;
	}

	override function get_wasMoved()
	{
		return startTimeWasChanged || endTimeWasChanged;
	}
}

enum Modifier
{
	MIRROR;
	NO_LONG_NOTES;
	FULL_LONG_NOTES;
	INVERSE;
}
