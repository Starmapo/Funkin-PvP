package ui.editors.song;

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

		if (state.noteGroup.getHoveredNote() != null)
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
			state.selectedNotes.clear();

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

		var seekTime:Float = 0;
		var startScrollY = (FlxG.height - 30);
		if (FlxG.mouse.globalY >= startScrollY && !state.inst.playing)
		{
			if (FlxG.mouse.globalY - startScrollY <= 10)
				seekTime = state.inst.time - 2;
			else if (FlxG.mouse.globalY - startScrollY <= 20)
				seekTime = state.inst.time - 6;
			else
				seekTime = state.inst.time - 50;

			if (seekTime < 0 || seekTime > state.inst.length)
				return;

			state.setSongTime(seekTime);
		}

		if (FlxG.mouse.globalY > 30 || state.inst.playing)
			return;

		if (30 - FlxG.mouse.globalY <= 10)
			seekTime = state.inst.time + 2;
		else if (30 - FlxG.mouse.globalY <= 20)
			seekTime = state.inst.time + 6;
		else
			seekTime = state.inst.time + 50;

		if (seekTime < 0 || seekTime > state.inst.length)
			return;

		state.setSongTime(seekTime);
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

			selectNotes(timeDragEnd, startLane, endLane);
		}

		isSelecting = false;
		visible = false;
		setPosition();
		resize(0, 0);
		startingPoint = null;
		timeDragStart = 0;
	}

	function selectNotes(timeDragEnd:Float, startLane:Int, endLane:Int)
	{
		var foundNotes:Array<NoteInfo> = [];
		for (note in state.song.notes)
		{
			var yInbetween = timeDragStart > timeDragEnd ? CoolUtil.inBetween(note.startTime, timeDragEnd,
				timeDragStart) : CoolUtil.inBetween(note.startTime, timeDragStart, timeDragEnd);
			var laneInbetween = startLane > endLane ? CoolUtil.inBetween(note.lane, endLane, startLane) : CoolUtil.inBetween(note.lane, startLane, endLane);
			if (yInbetween && laneInbetween)
				foundNotes.push(note);
		}

		for (note in foundNotes)
		{
			if (!state.selectedNotes.value.contains(note))
				state.selectedNotes.push(note);
		}
	}
}
