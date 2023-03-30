package util.editors.actions.song;

import data.song.CameraFocus;
import data.song.NoteInfo;
import data.song.SliderVelocity;
import data.song.Song;
import data.song.TimingPoint;
import flixel.math.FlxMath;
import states.editors.SongEditorState;
import util.editors.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	public static inline var ADD_NOTE:String = 'add-note';
	public static inline var REMOVE_NOTE:String = 'remove-note';
	public static inline var ADD_NOTE_BATCH:String = 'add-note-batch';
	public static inline var REMOVE_NOTE_BATCH:String = 'remove-note-batch';
	public static inline var RESIZE_LONG_NOTE:String = 'resize-long-note';
	public static inline var MOVE_OBJECTS:String = 'move-objects';
	public static inline var RESNAP_OBJECTS:String = 'resnap-objects';
	public static inline var FLIP_NOTES:String = 'flip-notes';
	public static inline var ADD_TIMING_POINT:String = 'add-point';
	public static inline var REMOVE_TIMING_POINT:String = 'remove-point';
	public static inline var ADD_SCROLL_VELOCITY:String = 'add-sv';
	public static inline var REMOVE_SCROLL_VELOCITY:String = 'remove-sv';
	public static inline var ADD_CAMERA_FOCUS:String = 'add-camera-focus';
	public static inline var REMOVE_CAMERA_FOCUS:String = 'remove-camera-focus';
	public static inline var ADD_CAMERA_FOCUS_BATCH:String = 'add-camera-focus-batch';
	public static inline var REMOVE_CAMERA_FOCUS_BATCH:String = 'remove-camera-focus-batch';
	public static inline var CHANGE_TITLE:String = 'change-title';
	public static inline var CHANGE_ARTIST:String = 'change-artist';
	public static inline var CHANGE_SOURCE:String = 'change-source';
	public static inline var CHANGE_DIFFICULTY_NAME:String = 'change-difficulty-name';
	public static inline var CHANGE_OPPONENT:String = 'change-opponent';
	public static inline var CHANGE_BF:String = 'change-bf';
	public static inline var CHANGE_GF:String = 'change-gf';
	public static inline var CHANGE_INITIAL_SV:String = 'change-initial-sv';

	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}

	public function addNote(lane:Int, startTime:Int, endTime:Int = 0, type:String = '', params:String = '')
	{
		var note = new NoteInfo({
			startTime: startTime,
			lane: lane,
			endTime: endTime,
			type: type,
			params: params
		});
		perform(new ActionAddNote(state, note));
		return note;
	}

	public function addCamFocus(startTime:Float, char:CameraFocusChar = OPPONENT)
	{
		var camFocus = new CameraFocus({
			startTime: startTime,
			char: char
		});
		perform(new ActionAddCameraFocus(state, camFocus));
		return camFocus;
	}
}

class ActionAddNote implements IAction
{
	public var type:String = SongEditorActionManager.ADD_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;

	public function new(state:SongEditorState, note:NoteInfo)
	{
		this.state = state;
		this.note = note;
	}

	public function perform()
	{
		state.song.notes.push(note);
		state.song.sort();
		state.actionManager.triggerEvent(type, {
			note: note
		});
	}

	public function undo()
	{
		new ActionRemoveNote(state, note).perform();
	}
}

class ActionRemoveNote implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;

	public function new(state:SongEditorState, note:NoteInfo)
	{
		this.state = state;
		this.note = note;
	}

	public function perform()
	{
		state.song.notes.remove(note);
		state.song.sort();
		state.selectedNotes.remove(note);
		state.actionManager.triggerEvent(type, {
			note: note
		});
	}

	public function undo()
	{
		new ActionAddNote(state, note).perform();
	}
}

class ActionAddNoteBatch implements IAction
{
	public var type:String = SongEditorActionManager.ADD_NOTE_BATCH;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;

	public function new(state:SongEditorState, notes:Array<NoteInfo>)
	{
		this.state = state;
		this.notes = notes;
	}

	public function perform()
	{
		for (note in notes)
			state.song.notes.push(note);

		state.song.sort();
		state.actionManager.triggerEvent(type, {notes: notes});
	}

	public function undo()
	{
		new ActionRemoveNoteBatch(state, notes).perform();
	}
}

class ActionRemoveNoteBatch implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_NOTE_BATCH;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;

	public function new(state:SongEditorState, notes:Array<NoteInfo>)
	{
		this.state = state;
		this.notes = notes;
	}

	public function perform()
	{
		for (note in notes)
		{
			state.song.notes.remove(note);
			state.selectedNotes.remove(note);
		}
		state.song.sort();
		state.actionManager.triggerEvent(type, {notes: notes});
	}

	public function undo()
	{
		new ActionAddNoteBatch(state, notes).perform();
	}
}

class ActionResizeLongNote implements IAction
{
	public var type:String = SongEditorActionManager.RESIZE_LONG_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;
	var originalTime:Int;
	var newTime:Int;

	public function new(state:SongEditorState, note:NoteInfo, originalTime:Int, newTime:Int)
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

class ActionMoveObjects implements IAction
{
	public var type:String = SongEditorActionManager.MOVE_OBJECTS;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;
	var camFocuses:Array<CameraFocus>;
	var laneOffset:Int;
	var dragOffset:Int;
	var shouldPerform:Bool;

	public function new(state:SongEditorState, ?notes:Array<NoteInfo>, ?camFocuses:Array<CameraFocus>, laneOffset:Int, dragOffset:Int,
			shouldPerform:Bool = true)
	{
		this.state = state;
		this.notes = notes;
		this.camFocuses = camFocuses;
		this.laneOffset = laneOffset;
		this.dragOffset = dragOffset;
		this.shouldPerform = shouldPerform;
	}

	public function perform()
	{
		if (shouldPerform)
		{
			for (obj in notes)
			{
				obj.startTime += dragOffset;
				if (obj.isLongNote)
					obj.endTime += dragOffset;
				obj.lane += laneOffset;
			}
			for (obj in camFocuses)
				obj.startTime += dragOffset;
		}

		state.actionManager.triggerEvent(type, {notes: notes, camFocuses: camFocuses});
	}

	public function undo()
	{
		new ActionMoveObjects(state, notes, camFocuses, -laneOffset, -dragOffset).perform();
		shouldPerform = true;
	}
}

class ActionResnapObjects implements IAction
{
	public var type:String = SongEditorActionManager.RESNAP_OBJECTS;

	var state:SongEditorState;
	var snaps:Array<Int>;
	var notes:Array<NoteInfo>;
	var camFocuses:Array<CameraFocus>;
	var noteTimeAdjustments:Map<NoteInfo, NoteAdjustment> = new Map();
	var camFocusTimeAdjustments:Map<CameraFocus, CamFocusAdjustment> = new Map();

	public function new(state:SongEditorState, snaps:Array<Int>, ?notes:Array<NoteInfo>, ?camFocuses:Array<CameraFocus>)
	{
		this.state = state;
		this.snaps = snaps;
		this.notes = notes;
		this.camFocuses = camFocuses;
	}

	public function perform()
	{
		var resnapCount = 0;
		if (notes != null)
		{
			for (obj in notes)
			{
				var originalStartTime = obj.startTime;
				var originalEndTime = obj.endTime;
				obj.startTime = Math.round(closestTickOverall(obj.startTime));
				if (obj.isLongNote)
					obj.endTime = Math.round(closestTickOverall(obj.endTime));

				var adjustment = new NoteAdjustment(originalStartTime, originalEndTime, obj);
				if (adjustment.wasMoved)
				{
					noteTimeAdjustments.set(obj, adjustment);
					resnapCount++;
				}
			}
		}
		if (camFocuses != null)
		{
			for (obj in camFocuses)
			{
				var originalStartTime = obj.startTime;
				obj.startTime = closestTickOverall(obj.startTime);

				var adjustment = new CamFocusAdjustment(originalStartTime, obj);
				if (adjustment.wasMoved)
				{
					camFocusTimeAdjustments.set(obj, adjustment);
					resnapCount++;
				}
			}
		}

		if (resnapCount > 0)
		{
			state.actionManager.triggerEvent(type, {
				snaps: snaps,
				notes: notes,
				camFocuses: camFocuses
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
		for (obj => adjustment in camFocusTimeAdjustments)
		{
			obj.startTime = adjustment.originalStartTime;
		}

		state.actionManager.triggerEvent(type, {
			snaps: snaps,
			notes: notes,
			camFocuses: camFocuses
		});

		noteTimeAdjustments.clear();
		camFocusTimeAdjustments.clear();
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
				{
					note.lane = 7 - (note.lane - 4);
				}
				else
				{
					note.lane = 3 - note.lane;
				}
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

class ActionAddTimingPoint implements IAction
{
	public var type:String = SongEditorActionManager.ADD_TIMING_POINT;

	var state:SongEditorState;
	var timingPoint:TimingPoint;

	public function new(state:SongEditorState, timingPoint:TimingPoint)
	{
		this.state = state;
		this.timingPoint = timingPoint;
	}

	public function perform()
	{
		state.song.timingPoints.push(timingPoint);
		state.song.sort();
		state.actionManager.triggerEvent(type, {timingPoint: timingPoint});
	}

	public function undo()
	{
		new ActionRemoveTimingPoint(state, timingPoint).perform();
	}
}

class ActionRemoveTimingPoint implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_TIMING_POINT;

	var state:SongEditorState;
	var timingPoint:TimingPoint;

	public function new(state:SongEditorState, timingPoint:TimingPoint)
	{
		this.state = state;
		this.timingPoint = timingPoint;
	}

	public function perform()
	{
		state.song.timingPoints.remove(timingPoint);
		state.actionManager.triggerEvent(type, {timingPoint: timingPoint});
	}

	public function undo()
	{
		new ActionAddTimingPoint(state, timingPoint).perform();
	}
}

class ActionAddScrollVelocity implements IAction
{
	public var type:String = SongEditorActionManager.ADD_SCROLL_VELOCITY;

	var state:SongEditorState;
	var scrollVelocity:SliderVelocity;

	public function new(state:SongEditorState, scrollVelocity:SliderVelocity)
	{
		this.state = state;
		this.scrollVelocity = scrollVelocity;
	}

	public function perform()
	{
		state.song.sliderVelocities.push(scrollVelocity);
		state.song.sort();
		state.actionManager.triggerEvent(type, {scrollVelocity: scrollVelocity});
	}

	public function undo()
	{
		new ActionRemoveScrollVelocity(state, scrollVelocity).perform();
	}
}

class ActionRemoveScrollVelocity implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_SCROLL_VELOCITY;

	var state:SongEditorState;
	var scrollVelocity:SliderVelocity;

	public function new(state:SongEditorState, scrollVelocity:SliderVelocity)
	{
		this.state = state;
		this.scrollVelocity = scrollVelocity;
	}

	public function perform()
	{
		state.song.sliderVelocities.remove(scrollVelocity);
		state.actionManager.triggerEvent(type, {scrollVelocity: scrollVelocity});
	}

	public function undo()
	{
		new ActionAddScrollVelocity(state, scrollVelocity).perform();
	}
}

class ActionAddCameraFocus implements IAction
{
	public var type:String = SongEditorActionManager.ADD_CAMERA_FOCUS;

	var state:SongEditorState;
	var camFocus:CameraFocus;

	public function new(state:SongEditorState, camFocus:CameraFocus)
	{
		this.state = state;
		this.camFocus = camFocus;
	}

	public function perform()
	{
		state.song.cameraFocuses.push(camFocus);
		state.song.sort();
		state.actionManager.triggerEvent(type, {camFocus: camFocus});
	}

	public function undo()
	{
		new ActionRemoveCameraFocus(state, camFocus).perform();
	}
}

class ActionRemoveCameraFocus implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_CAMERA_FOCUS;

	var state:SongEditorState;
	var camFocus:CameraFocus;

	public function new(state:SongEditorState, camFocus:CameraFocus)
	{
		this.state = state;
		this.camFocus = camFocus;
	}

	public function perform()
	{
		state.song.cameraFocuses.remove(camFocus);
		state.actionManager.triggerEvent(type, {camFocus: camFocus});
	}

	public function undo()
	{
		new ActionAddCameraFocus(state, camFocus).perform();
	}
}

class ActionAddCameraFocusBatch implements IAction
{
	public var type:String = SongEditorActionManager.ADD_CAMERA_FOCUS_BATCH;

	var state:SongEditorState;
	var camFocuses:Array<CameraFocus>;

	public function new(state:SongEditorState, camFocuses:Array<CameraFocus>)
	{
		this.state = state;
		this.camFocuses = camFocuses;
	}

	public function perform()
	{
		for (camFocus in camFocuses)
			state.song.cameraFocuses.push(camFocus);
		state.song.sort();
		state.actionManager.triggerEvent(type, {camFocuses: camFocuses});
	}

	public function undo()
	{
		new ActionRemoveCameraFocusBatch(state, camFocuses).perform();
	}
}

class ActionRemoveCameraFocusBatch implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_CAMERA_FOCUS_BATCH;

	var state:SongEditorState;
	var camFocuses:Array<CameraFocus>;

	public function new(state:SongEditorState, camFocuses:Array<CameraFocus>)
	{
		this.state = state;
		this.camFocuses = camFocuses;
	}

	public function perform()
	{
		for (camFocus in camFocuses)
		{
			state.song.cameraFocuses.remove(camFocus);
			state.selectedCamFocuses.remove(camFocus);
		}
		state.actionManager.triggerEvent(type, {camFocuses: camFocuses});
	}

	public function undo()
	{
		new ActionAddCameraFocusBatch(state, camFocuses).perform();
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

class NoteAdjustment
{
	public var originalStartTime:Int;
	public var originalEndTime:Int;
	public var newStartTime:Int;
	public var newEndTime:Int;
	public var startTimeWasChanged(get, never):Bool;
	public var endTimeWasChanged(get, never):Bool;
	public var wasMoved(get, never):Bool;

	public function new(originalStartTime:Int, originalEndTime:Int, info:NoteInfo)
	{
		this.originalStartTime = originalStartTime;
		this.originalEndTime = originalEndTime;
		newStartTime = info.startTime;
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

	function get_wasMoved()
	{
		return startTimeWasChanged || endTimeWasChanged;
	}
}

class CamFocusAdjustment
{
	public var originalStartTime:Float;
	public var newStartTime:Float;
	public var wasMoved(get, never):Bool;

	public function new(originalStartTime:Float, info:CameraFocus)
	{
		this.originalStartTime = originalStartTime;
		newStartTime = info.startTime;
	}

	function get_wasMoved()
	{
		return originalStartTime != newStartTime;
	}
}
