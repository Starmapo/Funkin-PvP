package ui.editors.song;

import data.Settings;
import data.song.CameraFocus.CameraFocusChar;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
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
	var objectMoveInitialMousePosition:FlxPoint;
	var objectMoveGrabOffset:Float;
	var noteInDrag:SongEditorNote;
	var camFocusInDrag:SongEditorCamFocus;
	var timeDragStart:Float;
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

			if ((objectMoveInitialMousePosition != null && previousLaneDragOffset != 0)
				|| ((noteInDrag != null || camFocusInDrag != null) && previousDragOffset != 0))
				state.actionManager.perform(new ActionMoveObjects(state, state.selectedNotes.value.copy(), state.selectedCamFocuses.value.copy(),
					columnOffset, previousDragOffset, false));

			objectMoveInitialMousePosition = null;
			noteInDrag = null;
			camFocusInDrag = null;
			timeDragStart = 0;
			previousDragOffset = 0;
			previousLaneDragOffset = 0;
			columnOffset = 0;
			objectMoveGrabOffset = 0;
		}

		if (isHovered)
		{
			handleLeftClick();
			handleRightClick();
		}

		handleLongNoteDragging();
		handleMovingObjects();
	}

	function handleLeftClick()
	{
		if (!FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL && state.currentTool.value == OBJECT)
				handleObjectPlacement();

			return;
		}

		var note = state.noteGroup.getHoveredNote();
		var camFocus = state.camFocusGroup.getHoveredCamFocus();

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
			}

			if (state.currentTool.value == SELECT)
				return;
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
			state.notificationManager.showNotification("You can't place there, there's already an object at that time.", ERROR);
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

	function handleRightClick()
	{
		if (!FlxG.mouse.justPressedRight)
		{
			if (FlxG.mouse.pressedRight && FlxG.keys.pressed.CONTROL)
				removeHoveredObject();

			return;
		}

		removeHoveredObject();
	}

	function removeHoveredObject()
	{
		var note = state.noteGroup.getHoveredNote();
		if (note != null)
		{
			if (state.selectedNotes.value.contains(note.info))
				state.deleteSelectedObjects();
			else
				state.actionManager.perform(new ActionRemoveNote(state, note.info));

			return;
		}

		var camFocus = state.camFocusGroup.getHoveredCamFocus();
		if (camFocus != null)
		{
			if (state.selectedCamFocuses.value.contains(camFocus.info))
				state.deleteSelectedObjects();
			else
				state.actionManager.perform(new ActionRemoveCameraFocus(state, camFocus.info));

			return;
		}
	}

	function handleLongNoteDragging()
	{
		if (longNoteInDrag == null || !isHeld)
			return;

		var time = Math.round(state.getTimeFromY(FlxG.mouse.globalY) / state.trackSpeed);
		time = getNearestTickFromTime(time, state.beatSnap.value);

		if (time <= longNoteInDrag.info.startTime)
		{
			if (!isDraggingLongNoteBackwards && time < longNoteInDrag.info.startTime)
			{
				longNoteInDrag.info.endTime = longNoteInDrag.info.startTime;
				isDraggingLongNoteBackwards = true;
			}

			longNoteInDrag.info.startTime = time;

			if (time == longNoteInDrag.info.startTime && !isDraggingLongNoteBackwards)
			{
				longNoteInDrag.info.endTime = 0;
				longNoteInDrag.refreshPositionAndSize();
				return;
			}

			longNoteInDrag.refreshPositionAndSize();
			return;
		}

		if (isDraggingLongNoteBackwards && time > longNoteInDrag.info.startTime)
			longNoteInDrag.info.startTime = time;

		if (longNoteInDrag.info.startTime == longNoteInDrag.info.endTime)
		{
			longNoteInDrag.info.endTime = 0;
			isDraggingLongNoteBackwards = false;
		}

		if (!isDraggingLongNoteBackwards)
			longNoteInDrag.info.endTime = time;

		longNoteInDrag.refreshPositionAndSize();
	}

	function handleMovingObjects()
	{
		if ((state.selectedNotes.value.length == 0 && state.selectedCamFocuses.value.length == 0) || !isHeld)
			return;

		state.handleMouseSeek();

		if (objectMoveInitialMousePosition == null && noteInDrag == null && camFocusInDrag == null)
		{
			var hoveredNote = state.noteGroup.getHoveredNote();
			var hoveredCamFocus = state.camFocusGroup.getHoveredCamFocus();
			if (hoveredNote == null && hoveredCamFocus == null)
				return;

			noteInDrag = hoveredNote;
			camFocusInDrag = hoveredCamFocus;
			objectMoveInitialMousePosition = FlxG.mouse.getGlobalPosition();

			if (noteInDrag != null && noteInDrag.info.isLongNote)
			{
				var relativeMouseY = state.hitPositionY - Math.round(state.getTimeFromY(FlxG.mouse.globalY));
				objectMoveGrabOffset = relativeMouseY - noteInDrag.y;
			}
			else
				objectMoveGrabOffset = 0;

			if (hoveredNote != null)
				timeDragStart = hoveredNote.info.startTime;
			else
				timeDragStart = camFocusInDrag.info.startTime;
			previousDragOffset = 0;
			previousLaneDragOffset = 0;
			columnOffset = 0;
		}

		if ((objectMoveInitialMousePosition - FlxG.mouse.getGlobalPosition()).isZero())
			return;

		var time = getNearestTickFromTime(Math.round(state.getTimeFromY(FlxG.mouse.globalY - objectMoveGrabOffset) / state.trackSpeed), state.beatSnap.value);
		var offset = Math.round(time - timeDragStart);
		var laneOffset = FlxMath.boundInt(state.getLaneFromX(FlxG.mouse.globalX), 0, 7)
			- FlxMath.boundInt(state.getLaneFromX(objectMoveInitialMousePosition.x), 0, 7);

		if (longNoteInDrag != null || time < 0)
			return;

		var dragXAllowed = true;

		if (state.selectedNotes.value.length > 1 && previousLaneDragOffset != laneOffset)
		{
			var columnOffset = laneOffset - previousLaneDragOffset;
			var leftColumn = FlxMath.MAX_VALUE_INT;
			var rightColumn = 0;

			for (note in state.selectedNotes.value)
			{
				leftColumn = FlxMath.minInt(note.lane, leftColumn);
				rightColumn = FlxMath.maxInt(note.lane, rightColumn);
			}

			if (laneOffset > previousLaneDragOffset)
				dragXAllowed = rightColumn + columnOffset <= 7;
			else if (laneOffset < previousLaneDragOffset)
				dragXAllowed = leftColumn + columnOffset >= 0;
		}

		for (i in 0...state.selectedNotes.value.length)
		{
			var obj = state.selectedNotes.value[i];
			if (previousDragOffset != offset)
			{
				var startTime = obj.startTime + (offset - previousDragOffset);
				obj.startTime = FlxMath.boundInt(startTime, 0, Math.round(state.inst.length));
				if (obj.isLongNote && startTime >= 0)
					obj.endTime = FlxMath.boundInt(obj.endTime + (offset - previousDragOffset), 0, Math.round(state.inst.length));
			}

			if (previousLaneDragOffset == laneOffset || !dragXAllowed)
				continue;

			var column = obj.lane;
			obj.lane = FlxMath.boundInt(obj.lane + (laneOffset - previousLaneDragOffset), 0, 7);

			if (i == 0)
				columnOffset += obj.lane - column;
		}
		if (previousDragOffset != offset)
		{
			for (i in 0...state.selectedCamFocuses.value.length)
			{
				var obj = state.selectedCamFocuses.value[i];
				var startTime = obj.startTime + (offset - previousDragOffset);
				obj.startTime = FlxMath.bound(startTime, 0, Math.round(state.inst.length));
			}
		}

		for (obj in state.noteGroup.notes)
		{
			if (state.selectedNotes.value.contains(obj.info))
			{
				obj.updateAnims();
				obj.refreshPositionAndSize();
			}
		}
		for (obj in state.camFocusGroup.camFocuses)
		{
			if (state.selectedCamFocuses.value.contains(obj.info))
			{
				obj.updatePosition();
			}
		}

		previousDragOffset = offset;
		previousLaneDragOffset = laneOffset;
	}
}
