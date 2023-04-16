package ui.editors.song;

import data.Settings;
import data.song.CameraFocus.CameraFocusChar;
import data.song.ITimingObject;
import data.song.NoteInfo;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import states.editors.SongEditorState;
import ui.editors.song.SongEditorNoteGroup.SongEditorNote;
import util.editors.song.SongEditorActionManager;

class SongEditorPlayfieldButton extends FlxSprite
{
	public var isHovered:Bool = false;
	public var isHeld:Bool = false;

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var longNoteInDrag:SongEditorNote;
	var longNoteResizeOriginalEndTime:Float = -1;
	var isDraggingLongNoteBackwards:Bool = false;
	var objectMoveInitialMousePosition:FlxPoint;
	var objectMoveGrabOffset:Float;
	var objectInDrag:ISongEditorTimingObject;
	var timeDragStart:Float;
	var previousDragOffset:Float;
	var previousLaneDragOffset:Int;
	var columnOffset:Int;

	public function new(x:Float = 0, y:Float = 0, state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super(x, y);
		this.state = state;
		this.playfield = playfield;

		makeGraphic(Std.int(playfield.bg.width - playfield.borderLeft.width * 2), Std.int(playfield.bg.height - state.playfieldTabs.height),
			FlxColor.TRANSPARENT);
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

		if (isHeld && !state.selector.isSelecting)
			state.handleMouseSeek();

		handleInput();
	}

	function handleInput()
	{
		if (!isHeld)
		{
			if (longNoteInDrag != null
				&& longNoteResizeOriginalEndTime != longNoteInDrag.noteInfo.endTime
				&& longNoteResizeOriginalEndTime != -1)
				state.actionManager.perform(new ActionResizeLongNote(state, longNoteInDrag.noteInfo, longNoteResizeOriginalEndTime,
					longNoteInDrag.noteInfo.endTime));
			else if (longNoteInDrag != null)
				state.actionManager.triggerEvent(SongEditorActionManager.RESIZE_LONG_NOTE,
					{note: longNoteInDrag.info, originalTime: longNoteInDrag.noteInfo.endTime, newTime: longNoteInDrag.noteInfo.endTime});

			longNoteInDrag = null;
			longNoteResizeOriginalEndTime = -1;
			isDraggingLongNoteBackwards = false;

			if ((objectMoveInitialMousePosition != null && previousLaneDragOffset != 0)
				|| (objectInDrag != null && previousDragOffset != 0))
				state.actionManager.perform(new ActionMoveObjects(state, state.selectedObjects.value.copy(), columnOffset, previousDragOffset, false));

			objectMoveInitialMousePosition = null;
			objectInDrag = null;
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

		var object = playfield.getHoveredObject();

		if (object == null && FlxG.keys.released.CONTROL)
		{
			state.clearSelection();
		}

		if (state.currentTool.value == SELECT || state.currentTool.value == LONG_NOTE)
		{
			if (object != null && (state.currentTool.value == SELECT || Std.isOfType(object, SongEditorNote)))
			{
				handleObjectSelectTool(object);
				return;
			}

			if (state.currentTool.value == SELECT)
				return;
		}

		handleObjectPlacement();
	}

	function handleObjectPlacement()
	{
		var time = state.getTimeFromY(FlxG.mouse.globalY) / state.trackSpeed;
		time = getNearestTickFromTime(time, state.beatSnap.value);

		var lane = playfield.getLaneFromX(FlxG.mouse.globalX);
		if (existsObjectAtTimeAndLane(time, lane))
			return;

		switch (state.currentTool.value)
		{
			case OBJECT:
				if (playfield.type == OTHER)
				{
					switch (lane)
					{
						case 0: // Timing Point
							var bpm:Float = 120;
							var meter = 4;
							var curTimingPoint = state.song.getTimingPointAt(time);
							if (curTimingPoint != null)
							{
								bpm = curTimingPoint.bpm;
								meter = curTimingPoint.meter;
							}
							state.actionManager.addTimingPoint(time, bpm, meter);
						case 1: // Scroll Velocity
							var curSV = state.song.getScrollVelocityAt(time);
							var multipliers:Array<Float> = curSV != null ? curSV.multipliers.copy() : [1, 1];
							var linked = curSV != null ? curSV.linked : true;
							state.actionManager.addScrollVelocity(time, multipliers, linked);
						case 2: // Camera Focus
							var char:CameraFocusChar = OPPONENT;
							var curFocus = state.song.getCameraFocusAt(time);
							if (curFocus != null && curFocus.char == OPPONENT)
								char = BF;
							state.actionManager.addCamFocus(time, char);
					}
				}
				else
					state.actionManager.addNote(lane, time);
			case LONG_NOTE:
				if (playfield.type == NOTES)
				{
					var info = state.actionManager.addNote(lane, time);
					var longNote = null;
					for (note in playfield.noteGroup.notes)
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
					state.notificationManager.showNotification("You can't place a long note there! Switch to the 'Notes' section.", ERROR);
			default:
		}
	}

	function getNearestTickFromTime(time:Float, snap:Int)
	{
		var point = state.song.getTimingPointAt(time);
		if (point == null)
			return time;

		var timeFwd = Song.getNearestSnapTimeFromTime(state.song, true, snap, time);
		var timeBwd = Song.getNearestSnapTimeFromTime(state.song, false, snap, time);

		var fwdDiff = Math.abs(time - timeFwd);
		var bwdDiff = Math.abs(time - timeBwd);

		if (Math.abs(fwdDiff - bwdDiff) <= 2)
		{
			var snapTimePerBeat = point.beatLength / snap;
			if (Settings.editorPlaceOnNearestTick.value)
				return Song.getNearestSnapTimeFromTime(state.song, false, snap, time + snapTimePerBeat);

			return Song.getNearestSnapTimeFromTime(state.song, true, snap, time - snapTimePerBeat);
		}

		if (!Settings.editorPlaceOnNearestTick.value)
			return timeBwd;

		if (bwdDiff < fwdDiff)
			time = timeBwd;
		else if (fwdDiff < bwdDiff)
			time = timeFwd;

		return time;
	}

	function existsObjectAtTimeAndLane(time:Float, lane:Int)
	{
		if (playfield.type == NOTES)
		{
			for (i in 0...state.song.notes.length)
			{
				var note = state.song.notes[i];

				if (note.lane != lane)
					continue;

				if (!note.isLongNote && Std.int(note.startTime) == Std.int(time))
					return true;

				if (note.isLongNote && Std.int(time) >= Std.int(note.startTime) && Std.int(time) <= Std.int(note.endTime))
					return true;
			}
		}
		else
		{
			var objects:Array<ITimingObject> = switch (lane)
			{
				case 0:
					cast state.song.timingPoints;
				case 1:
					cast state.song.scrollVelocities;
				case 2:
					cast state.song.cameraFocuses;
				default:
					[];
			}
			for (i in 0...objects.length)
			{
				if (Std.int(objects[i].startTime) == Std.int(time))
					return true;
			}
		}

		return false;
	}

	function handleObjectSelectTool(obj:ISongEditorTimingObject)
	{
		if (obj == null)
			return;

		if (Std.isOfType(obj, SongEditorNote))
		{
			var obj:SongEditorNote = cast obj;
			if (obj.noteInfo.isLongNote && FlxG.mouse.overlaps(obj.tail))
			{
				longNoteInDrag = obj;
				longNoteResizeOriginalEndTime = obj.noteInfo.endTime;
				return;
			}
		}

		if (state.currentTool.value != SELECT)
			return;

		if (FlxG.keys.pressed.CONTROL)
		{
			if (state.selectedObjects.value.contains(obj.info))
				state.selectedObjects.remove(obj.info);
			else
				state.selectedObjects.push(obj.info);

			return;
		}

		if (!state.selectedObjects.value.contains(obj.info))
		{
			state.clearSelection();
			state.selectedObjects.push(obj.info);
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
		var obj = playfield.getHoveredObject();
		if (obj != null)
		{
			removeObject(obj);
			return;
		}
	}

	function removeObject(object:ISongEditorTimingObject)
	{
		if (state.selectedObjects.value.contains(object.info))
			state.deleteSelectedObjects();
		else
			state.actionManager.perform(new ActionRemoveObject(state, object.info));
	}

	function handleLongNoteDragging()
	{
		if (longNoteInDrag == null || !isHeld)
			return;

		var time = state.getTimeFromY(FlxG.mouse.globalY) / state.trackSpeed;
		time = getNearestTickFromTime(time, state.beatSnap.value);

		if (time <= longNoteInDrag.info.startTime)
		{
			if (!isDraggingLongNoteBackwards && time < longNoteInDrag.info.startTime)
			{
				longNoteInDrag.noteInfo.endTime = longNoteInDrag.info.startTime;
				isDraggingLongNoteBackwards = true;
			}

			longNoteInDrag.info.startTime = time;

			if (time == longNoteInDrag.info.startTime && !isDraggingLongNoteBackwards)
				longNoteInDrag.noteInfo.endTime = 0;

			longNoteInDrag.refreshPositionAndSize();
			return;
		}

		if (isDraggingLongNoteBackwards && time > longNoteInDrag.info.startTime)
			longNoteInDrag.info.startTime = time;

		if (longNoteInDrag.info.startTime == longNoteInDrag.noteInfo.endTime)
		{
			longNoteInDrag.noteInfo.endTime = 0;
			isDraggingLongNoteBackwards = false;
		}

		if (!isDraggingLongNoteBackwards)
			longNoteInDrag.noteInfo.endTime = time;

		longNoteInDrag.refreshPositionAndSize();
	}

	function handleMovingObjects()
	{
		if (state.selectedObjects.value.length == 0 || !isHeld)
			return;

		if (objectMoveInitialMousePosition == null && objectInDrag == null)
		{
			var hoveredObject = playfield.getHoveredObject();
			if (hoveredObject == null)
				return;

			objectInDrag = hoveredObject;
			objectMoveInitialMousePosition = FlxG.mouse.getGlobalPosition();

			if (Std.isOfType(objectInDrag, SongEditorNote))
			{
				var noteInDrag:SongEditorNote = cast objectInDrag;
				if (noteInDrag.noteInfo.isLongNote && !FlxG.mouse.overlaps(noteInDrag.head))
				{
					var relativeMouseY = state.hitPositionY - state.getTimeFromY(FlxG.mouse.globalY);
					objectMoveGrabOffset = relativeMouseY - objectInDrag.y;
				}
				else
					objectMoveGrabOffset = 0;
			}
			else
				objectMoveGrabOffset = 0;

			timeDragStart = hoveredObject.info.startTime;
			previousDragOffset = 0;
			previousLaneDragOffset = 0;
			columnOffset = 0;
		}

		if ((objectMoveInitialMousePosition - FlxG.mouse.getGlobalPosition()).isZero())
			return;

		if (longNoteInDrag != null)
			return;

		var time = FlxMath.bound(getNearestTickFromTime(state.getTimeFromY(FlxG.mouse.globalY - objectMoveGrabOffset) / state.trackSpeed,
			state.beatSnap.value), 0,
			state.inst.length);
		var offset = time - timeDragStart;
		var difference = offset - previousDragOffset;
		if (difference != 0)
		{
			state.selectedObjects.value.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime));
			if (!CoolUtil.inBetween(state.selectedObjects.value[0].startTime + difference, 0, state.inst.length))
				offset = previousDragOffset;
		}

		var laneOffset = FlxMath.boundInt(playfield.getLaneFromX(FlxG.mouse.globalX), 0, 7)
			- FlxMath.boundInt(playfield.getLaneFromX(objectMoveInitialMousePosition.x), 0, 7);
		var dragXAllowed = true;

		if (state.selectedObjects.value.length > 1 && previousLaneDragOffset != laneOffset)
		{
			var notes:Array<NoteInfo> = [];
			for (obj in state.selectedObjects.value)
			{
				if (Std.isOfType(obj, NoteInfo))
					notes.push(cast obj);
			}

			if (notes.length > 1)
			{
				var columnOffset = laneOffset - previousLaneDragOffset;
				var leftColumn = FlxMath.MAX_VALUE_INT;
				var rightColumn = 0;

				for (note in notes)
				{
					leftColumn = FlxMath.minInt(note.lane, leftColumn);
					rightColumn = FlxMath.maxInt(note.lane, rightColumn);
				}

				if (laneOffset > previousLaneDragOffset)
					dragXAllowed = rightColumn + columnOffset <= 7;
				else if (laneOffset < previousLaneDragOffset)
					dragXAllowed = leftColumn + columnOffset >= 0;
			}
		}

		for (i in 0...state.selectedObjects.value.length)
		{
			var obj = state.selectedObjects.value[i];
			if (previousDragOffset != offset)
			{
				var startTime = obj.startTime + (offset - previousDragOffset);
				obj.startTime = FlxMath.bound(startTime, 0, state.inst.length);
				if (Std.isOfType(obj, NoteInfo))
				{
					var obj:NoteInfo = cast obj;
					if (obj.isLongNote && startTime >= 0)
						obj.endTime = FlxMath.bound(obj.endTime + (offset - previousDragOffset), 0, state.inst.length);
				}
			}

			if (!Std.isOfType(obj, NoteInfo) || previousLaneDragOffset == laneOffset || !dragXAllowed)
				continue;

			var obj:NoteInfo = cast obj;
			var column = obj.lane;
			obj.lane = FlxMath.boundInt(obj.lane + (laneOffset - previousLaneDragOffset), 0, 7);

			if (i == 0)
				columnOffset += obj.lane - column;
		}

		if (playfield.type == NOTES)
		{
			for (obj in playfield.noteGroup.notes)
			{
				if (state.selectedObjects.value.contains(obj.info))
				{
					obj.updateAnims();
					obj.refreshPositionAndSize();
				}
			}
		}
		else
		{
			for (objects in playfield.otherGroup.getAllObjects())
			{
				for (obj in objects)
				{
					if (state.selectedObjects.value.contains(obj.info))
						obj.updatePosition();
				}
			}
		}

		previousDragOffset = offset;
		previousLaneDragOffset = laneOffset;
	}
}
