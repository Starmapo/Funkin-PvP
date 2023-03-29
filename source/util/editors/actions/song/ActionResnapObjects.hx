package util.editors.actions.song;

import data.song.CameraFocus;
import data.song.NoteInfo;
import data.song.Song;
import flixel.math.FlxMath;
import states.editors.SongEditorState;

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
		for (note => adjustment in noteTimeAdjustments)
		{
			note.startTime = adjustment.originalStartTime;
			note.endTime = adjustment.originalEndTime;
		}

		state.actionManager.triggerEvent(type, {
			snaps: snaps,
			notes: notes
		});

		noteTimeAdjustments.clear();
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
