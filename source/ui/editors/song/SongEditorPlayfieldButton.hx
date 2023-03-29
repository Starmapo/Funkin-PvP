package ui.editors.song;

import data.Settings;
import data.song.CameraFocus.CameraFocusChar;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import states.editors.SongEditorState;
import ui.editors.song.SongEditorCamFocusGroup.SongEditorCamFocus;
import ui.editors.song.SongEditorNoteGroup.SongEditorNote;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorPlayfieldButton extends FlxSprite
{
	public var isHovered:Bool = false;
	public var isHeld:Bool = false;

	var state:SongEditorState;
	var longNoteInDrag:SongEditorNote;
	var longNoteResizeOriginalEndTime:Int = -1;
	var isDraggingLongNoteBackwards:Bool = false;
	var noteMoveInitialMousePosition:FlxPoint;
	var noteMoveGrabOffset:Float;
	var noteInDrag:SongEditorNote;
	var timeDragStart:Int;
	var previousDragOffset:Int;
	var previousLaneDragOffset:Int;
	var columnOffset:Int;

	public function new(x:Float = 0, y:Float = 0, state:SongEditorState)
	{
		super(x, y);
		this.state = state;

		makeGraphic(Std.int(state.playfieldBG.width - state.borderLeft.width * 2), Std.int(state.playfieldBG.height), FlxColor.TRANSPARENT);
		visible = false;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.mouse.overlaps(this))
		{
			isHovered = true;
			if (!isHeld && FlxG.mouse.justPressed)
				isHeld = true;
		}
		else
			isHovered = false;

		if (FlxG.mouse.released)
			isHeld = false;

		handleInput();
	}

	function handleInput()
	{
		if (!isHeld)
		{
			if (longNoteInDrag != null
				&& longNoteResizeOriginalEndTime != longNoteInDrag.info.endTime
				&& longNoteResizeOriginalEndTime != -1)
				state.actionManager.perform(new ActionResizeLongNote(state, longNoteInDrag.info, longNoteResizeOriginalEndTime, longNoteInDrag.info.endTime));
			else if (longNoteInDrag != null)
				state.actionManager.triggerEvent(SongEditorActionManager.RESIZE_LONG_NOTE,
					{note: longNoteInDrag.info, originalTime: longNoteInDrag.info.endTime, newTime: longNoteInDrag.info.endTime});

			longNoteInDrag = null;
			longNoteResizeOriginalEndTime = -1;
			isDraggingLongNoteBackwards = false;

			if ((noteMoveInitialMousePosition != null && previousLaneDragOffset != 0) || (noteInDrag != null && previousDragOffset != 0))
				state.actionManager.perform(new ActionMoveObjects(state, state.selectedNotes.value.copy(), state.selectedCamFocuses.value.copy(),
					columnOffset, previousDragOffset, false));

			noteMoveInitialMousePosition = null;
			noteInDrag = null;
			timeDragStart = 0;
			previousDragOffset = 0;
			previousLaneDragOffset = 0;
			columnOffset = 0;
			noteMoveGrabOffset = 0;
		}

		if (isHovered)
		{
			handleLeftClick();
		}
	}

	function handleLeftClick()
	{
		if (!FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL && state.currentTool.value == OBJECT)
				handleObjectPlacement();

			return;
		}

		trace('left click');

		var note = state.noteGroup.getHoveredNote();
		var camFocus = state.camFocusGroup.getHoveredCamFocus();

		trace('hovering note: ' + note != null);

		if (note == null && camFocus == null && FlxG.keys.released.CONTROL)
		{
			state.clearSelection();
		}

		if (state.currentTool.value == SELECT || state.currentTool.value == LONG_NOTE)
		{
			if (note != null)
				handleNoteSelectTool(note);
			else if (state.currentTool.value == SELECT)
			{
				if (camFocus != null)
					handleCamFocusSelectTool(camFocus);

				return;
			}
		}

		handleObjectPlacement();
	}

	function handleObjectPlacement()
	{
		var time = Math.round(state.getTimeFromY(FlxG.mouse.globalY) / state.trackSpeed);
		time = getNearestTickFromTime(time, state.beatSnap.value);

		var lane = state.getLaneFromX(FlxG.mouse.globalX);
		if (existsObjectAtTimeAndLane(time, lane))
		{
			state.notificationManager.showNotification("You can't place there, there's already an object at that time.");
			return;
		}

		switch (state.currentTool.value)
		{
			case OBJECT:
				if (lane == 8) // Camera Focuses
				{
					var char:CameraFocusChar = OPPONENT;
					var curFocus = state.song.getCameraFocusAt(time);
					if (curFocus != null)
						char = (curFocus.char == OPPONENT ? BF : OPPONENT);
					state.actionManager.addCamFocus(time, char);
				}
				else if (lane == 9) {} // Events
				else if (lane == 10) {} // Lyrics
				else
					state.actionManager.addNote(lane, time);
			case LONG_NOTE:
				if (lane < 8)
				{
					var info = state.actionManager.addNote(lane, time);
					var longNote = null;
					for (note in state.noteGroup.notes)
					{
						if (note.info == info)
						{
							longNote = note;
							break;
						}
					}
					longNoteInDrag = longNote;
				}
				else
					state.notificationManager.showNotification("You can't place a long note there!", ERROR);
			default:
		}
	}

	function existsObjectAtTimeAndLane(time:Int, lane:Int)
	{
		if (lane == 8)
		{
			for (i in 0...state.song.cameraFocuses.length)
			{
				var camFocus = state.song.cameraFocuses[i];
				if (camFocus.startTime == time)
					return true;
			}
			return false;
		}

		for (i in 0...state.song.notes.length)
		{
			var note = state.song.notes[i];

			if (note.lane != lane)
				continue;

			if (!note.isLongNote && note.startTime == time)
				return true;

			if (note.isLongNote && time >= note.startTime && time <= note.endTime)
				return true;
		}

		return false;
	}

	function handleNoteSelectTool(obj:SongEditorNote)
	{
		if (obj == null)
			return;

		if (obj.info.isLongNote && FlxG.mouse.overlaps(obj.tail))
		{
			longNoteInDrag = obj;
			longNoteResizeOriginalEndTime = obj.info.endTime;
			return;
		}

		if (state.currentTool.value != SELECT)
			return;

		trace('is selected: ' + state.selectedNotes.value.contains(obj.info));

		if (FlxG.keys.pressed.CONTROL)
		{
			if (state.selectedNotes.value.contains(obj.info))
				state.selectedNotes.remove(obj.info);
			else
				state.selectedNotes.push(obj.info);

			return;
		}

		if (!state.selectedNotes.value.contains(obj.info))
		{
			state.clearSelection();
			state.selectedNotes.push(obj.info);
		}
	}

	function handleCamFocusSelectTool(obj:SongEditorCamFocus)
	{
		if (obj == null)
			return;

		if (state.currentTool.value != SELECT)
			return;

		if (FlxG.keys.pressed.CONTROL)
		{
			if (state.selectedCamFocuses.value.contains(obj.info))
				state.selectedCamFocuses.remove(obj.info);
			else
				state.selectedCamFocuses.push(obj.info);

			return;
		}

		if (!state.selectedCamFocuses.value.contains(obj.info))
		{
			state.clearSelection();
			state.selectedCamFocuses.push(obj.info);
		}
	}

	function getNearestTickFromTime(time:Int, snap:Int)
	{
		var point = state.song.getTimingPointAt(time);
		if (point == null)
			return time;

		var timeFwd = Math.round(Song.getNearestSnapTimeFromTime(state.song, true, snap, time));
		var timeBwd = Math.round(Song.getNearestSnapTimeFromTime(state.song, false, snap, time));

		var fwdDiff = Math.round(Math.abs(time - timeFwd));
		var bwdDiff = Math.round(Math.abs(time - timeBwd));

		if (Math.abs(fwdDiff - bwdDiff) <= 2)
		{
			var snapTimePerBeat = point.beatLength / snap;
			if (Settings.editorPlaceOnNearestTick.value)
				return Math.round(Song.getNearestSnapTimeFromTime(state.song, false, snap, time + snapTimePerBeat));

			return Math.round(Song.getNearestSnapTimeFromTime(state.song, true, snap, time - snapTimePerBeat));
		}

		if (!Settings.editorPlaceOnNearestTick.value)
			return timeBwd;

		if (bwdDiff < fwdDiff)
			time = timeBwd;
		else if (fwdDiff < bwdDiff)
			time = timeFwd;

		return time;
	}
}
