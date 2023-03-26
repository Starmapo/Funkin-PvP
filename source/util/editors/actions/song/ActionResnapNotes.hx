package util.editors.actions.song;

import data.song.NoteInfo;
import data.song.Song;
import flixel.math.FlxMath;
import states.editors.SongEditorState;

class ActionResnapNotes implements IAction
{
	public var type:String = SongEditorActionManager.RESNAP_NOTES;

	var state:SongEditorState;
	var snaps:Array<Int>;
	var notes:Array<NoteInfo>;
	var noteTimeAdjustments:Map<NoteInfo, NoteAdjustment> = new Map();

	public function new(state:SongEditorState, snaps:Array<Int>, notes:Array<NoteInfo>)
	{
		this.state = state;
		this.snaps = snaps;
		this.notes = notes;
	}

	public function perform()
	{
		var resnapCount = 0;
		for (note in notes)
		{
			var originalStartTime = note.startTime;
			var originalEndTime = note.endTime;
			note.startTime = closestTickOverall(note.startTime);
			if (note.isLongNote)
				note.endTime = closestTickOverall(note.endTime);

			var adjustment = new NoteAdjustment(originalStartTime, originalEndTime, note);
			if (adjustment.noteWasMoved)
			{
				noteTimeAdjustments.set(note, adjustment);
				resnapCount++;
			}
		}
		trace(resnapCount);

		if (resnapCount > 0)
		{
			state.actionManager.triggerEvent(type, {
				snaps: snaps,
				notes: notes
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

	function closestTickOverall(time:Int)
	{
		var closestTime = FlxMath.MAX_VALUE_INT;
		for (snap in snaps)
		{
			var newTime = closestTickToSnap(time, snap);
			if (Math.abs(time - newTime) < Math.abs(time - closestTime))
				closestTime = newTime;
		}
		return closestTime;
	}

	function closestTickToSnap(time:Int, snap:Int)
	{
		var point = state.song.getTimingPointAt(time);
		if (point == null)
			return time;

		var timeFwd = Std.int(Song.getNearestSnapTimeFromTime(state.song, true, snap, time));
		var timeBwd = Std.int(Song.getNearestSnapTimeFromTime(state.song, false, snap, time));

		var fwdDiff = Std.int(Math.abs(time - timeFwd));
		var bwdDiff = Std.int(Math.abs(time - timeBwd));

		if (Math.abs(fwdDiff - bwdDiff) <= 2)
		{
			var snapTimePerBeat = 60000 / point.bpm / snap;
			return Std.int(Song.getNearestSnapTimeFromTime(state.song, false, snap, time + snapTimePerBeat));
		}

		var closestTime = time;

		if (bwdDiff < fwdDiff)
			closestTime = timeBwd;
		else if (fwdDiff < bwdDiff)
			closestTime = timeFwd;

		return closestTime;
	}
}

class NoteAdjustment
{
	public var originalStartTime:Int;
	public var originalEndTime:Int;
	public var newStartTime:Int;
	public var newEndTime:Int;
	public var isLongNote:Bool;
	public var startTimeWasChanged(get, never):Bool;
	public var endTimeWasChanged(get, never):Bool;
	public var noteWasMoved(get, never):Bool;

	public function new(originalStartTime:Int, originalEndTime:Int, note:NoteInfo)
	{
		this.originalStartTime = originalStartTime;
		this.originalEndTime = originalEndTime;
		newStartTime = note.startTime;
		newEndTime = note.endTime;
		isLongNote = note.isLongNote;
	}

	function get_startTimeWasChanged()
	{
		return originalStartTime != newStartTime;
	}

	function get_endTimeWasChanged()
	{
		return originalEndTime != newEndTime;
	}

	function get_noteWasMoved()
	{
		return startTimeWasChanged || endTimeWasChanged;
	}
}
