package ui.editors.song;

import data.song.CameraFocus;
import data.song.NoteInfo;
import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Rectangle;
import states.editors.SongEditorState;

class SongEditorSelector extends FlxUI9SliceSprite
{
	var state:SongEditorState;
	var isSelecting:Bool = false;
	var startingPoint:FlxPoint;
	var timeDragStart:Float;

	public function new(state:SongEditorState)
	{
		super(0, 0, Paths.getImage('editors/select'), new Rectangle(), [6, 6, 11, 11]);
		this.state = state;
		scrollFactor.set();
		visible = false;
	}

	override function update(elapsed:Float)
	{
		if (state.currentTool.value == SELECT)
		{
			handleSelection();
		}
	}

	function handleSelection()
	{
		if (FlxG.mouse.justReleased)
		{
			handleButtonReleased();
			return;
		}

		if (isSelecting)
			handleDrag();
		else
			handleButtonInitiallyPressed();
	}

	function handleButtonInitiallyPressed()
	{
		if (isSelecting || !FlxG.mouse.justPressed)
			return;

		if (state.isHoveringObject())
			return;

		if (FlxG.mouse.overlaps(state.seekBar.bg)
			|| FlxG.mouse.overlaps(state.zoomInButton)
			|| FlxG.mouse.overlaps(state.zoomOutButton)
			|| FlxG.mouse.overlaps(state.detailsPanel)
			|| FlxG.mouse.overlaps(state.compositionPanel)
			|| FlxG.mouse.overlaps(state.editPanel))
			return;

		var mousePos = FlxG.mouse.getGlobalPosition();
		var clickArea = new FlxRect(state.playfieldBG.x - 200, state.playfieldBG.y, state.playfieldBG.width + 400, state.playfieldBG.height);
		if (!clickArea.containsPoint(mousePos))
			return;

		if (FlxG.keys.released.CONTROL)
		{
			state.clearSelection();
		}

		isSelecting = true;
		visible = true;
		startingPoint = mousePos;
		timeDragStart = state.getTimeFromY(mousePos.y) / state.trackSpeed;
		setPosition(mousePos.x, mousePos.y);
	}

	function handleDrag()
	{
		if (!isSelecting || startingPoint == null)
			return;

		resize(Math.abs(FlxG.mouse.globalX - startingPoint.x), Math.abs(FlxG.mouse.globalY - startingPoint.y));
		setPosition(Math.min(startingPoint.x, FlxG.mouse.globalX), Math.min(startingPoint.y, FlxG.mouse.globalY));

		state.handleMouseSeek();
	}

	function handleButtonReleased()
	{
		if (startingPoint == null)
			return;

		var mousePos = FlxG.mouse.getGlobalPosition();
		var difference = startingPoint - mousePos;
		if (isSelecting && !difference.isZero())
		{
			var timeDragEnd = state.getTimeFromY(mousePos.y) / state.trackSpeed;
			var startLane = state.getLaneFromX(startingPoint.x);
			var endLane = state.getLaneFromX(mousePos.x);

			selectObjects(timeDragEnd, startLane, endLane);
		}

		isSelecting = false;
		visible = false;
		setPosition();
		resize(0, 0);
		startingPoint = null;
		timeDragStart = 0;
	}

	function selectObjects(timeDragEnd:Float, startLane:Int, endLane:Int)
	{
		var dragStart = Math.min(timeDragStart, timeDragEnd);
		var dragEnd = Math.max(timeDragStart, timeDragEnd);
		var realStartLane = Math.min(startLane, endLane);
		var realEndLane = Math.max(startLane, endLane);

		var foundNotes:Array<NoteInfo> = [];
		var foundCamFocuses:Array<CameraFocus> = [];

		for (obj in state.song.notes)
		{
			var yInbetween = CoolUtil.inBetween(obj.startTime, dragStart, dragEnd);
			var laneInbetween = CoolUtil.inBetween(obj.lane, realStartLane, realEndLane);
			if (yInbetween && laneInbetween)
				foundNotes.push(obj);
		}
		for (obj in state.song.cameraFocuses)
		{
			var yInbetween = CoolUtil.inBetween(obj.startTime, dragStart, dragEnd);
			var laneInbetween = CoolUtil.inBetween(8, realStartLane, realEndLane);
			if (yInbetween && laneInbetween)
				foundCamFocuses.push(obj);
		}

		for (obj in foundNotes)
		{
			if (!state.selectedNotes.value.contains(obj))
				state.selectedNotes.push(obj);
		}
		for (obj in foundCamFocuses)
		{
			if (!state.selectedCamFocuses.value.contains(obj))
				state.selectedCamFocuses.push(obj);
		}
	}
}
