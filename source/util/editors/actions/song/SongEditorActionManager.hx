package util.editors.actions.song;

import data.song.CameraFocus;
import data.song.ITimingObject;
import data.song.NoteInfo;
import data.song.Song;
import flixel.math.FlxMath;
import states.editors.SongEditorState;
import util.editors.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	public static inline var ADD_OBJECT:String = 'add-object';
	public static inline var REMOVE_OBJECT:String = 'remove-object';
	public static inline var ADD_OBJECT_BATCH:String = 'add-object-batch';
	public static inline var REMOVE_OBJECT_BATCH:String = 'remove-object-batch';
	public static inline var RESIZE_LONG_NOTE:String = 'resize-long-note';
	public static inline var MOVE_OBJECTS:String = 'move-objects';
	public static inline var RESNAP_OBJECTS:String = 'resnap-objects';
	public static inline var FLIP_NOTES:String = 'flip-notes';
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

	public function addCamFocus(startTime:Float, char:CameraFocusChar = OPPONENT)
	{
		var camFocus = new CameraFocus({
			startTime: startTime,
			char: char
		});
		perform(new ActionAddObject(state, camFocus));
		return camFocus;
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
	public var originalStartTime:Float;
	public var originalEndTime:Float;
	public var newStartTime:Float;
	public var newEndTime:Float;
	public var startTimeWasChanged(get, never):Bool;
	public var endTimeWasChanged(get, never):Bool;
	public var wasMoved(get, never):Bool;

	public function new(originalStartTime:Float, originalEndTime:Float, info:NoteInfo)
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
