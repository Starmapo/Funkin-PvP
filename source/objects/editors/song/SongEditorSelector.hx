package objects.editors.song;

import backend.structures.song.CameraFocus;
import backend.structures.song.ITimingObject;
import backend.structures.song.NoteInfo;
import flixel.FlxG;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import states.editors.SongEditorState;

class SongEditorSelector extends FlxUI9SliceSprite
{
	public var isSelecting:Bool = false;
	
	var state:SongEditorState;
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
	
	override function destroy()
	{
		super.destroy();
		state = null;
		startingPoint = FlxDestroyUtil.put(startingPoint);
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
			
		var playfield = state.playfield;
		
		if (playfield.isHoveringObject())
			return;
			
		if (FlxG.mouse.overlaps(state.seekBar.bg)
			|| FlxG.mouse.overlaps(state.zoomInButton)
			|| FlxG.mouse.overlaps(state.zoomOutButton)
			|| FlxG.mouse.overlaps(state.detailsPanel)
			|| FlxG.mouse.overlaps(state.compositionPanel)
			|| FlxG.mouse.overlaps(state.editPanel)
			|| FlxG.mouse.overlaps(state.playfieldTabs))
			return;
			
		var mousePos = FlxG.mouse.getGlobalPosition();
		var clickArea = new FlxRect(playfield.bg.x - 200, playfield.bg.y, playfield.bg.width + 400, playfield.bg.height);
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
			
		var playfield = state.playfield;
		var mousePos = FlxG.mouse.getGlobalPosition();
		var difference = startingPoint - mousePos;
		if (isSelecting && !difference.isZero())
		{
			var timeDragEnd = state.getTimeFromY(mousePos.y) / state.trackSpeed;
			var startLane = playfield.getLaneFromX(startingPoint.x);
			var endLane = playfield.getLaneFromX(mousePos.x);
			
			selectObjects(timeDragEnd, startLane, endLane);
		}
		difference.put();
		
		isSelecting = false;
		visible = false;
		setPosition();
		resize(0, 0);
		startingPoint = FlxDestroyUtil.put(startingPoint);
		timeDragStart = 0;
	}
	
	function selectObjects(timeDragEnd:Float, startLane:Int, endLane:Int)
	{
		var dragStart = Math.min(timeDragStart, timeDragEnd);
		var dragEnd = Math.max(timeDragStart, timeDragEnd);
		var realStartLane = FlxMath.minInt(startLane, endLane);
		var realEndLane = FlxMath.maxInt(startLane, endLane);
		
		var foundObjects:Array<ITimingObject> = [];
		
		if (state.playfield.type == NOTES)
		{
			for (obj in state.song.notes)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, obj.lane, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
		}
		else
		{
			for (obj in state.song.timingPoints)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, 0, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
			for (obj in state.song.scrollVelocities)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, 1, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
			for (obj in state.song.cameraFocuses)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, 2, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
			for (obj in state.song.events)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, 3, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
			for (obj in state.song.lyricSteps)
			{
				if (canSelectObject(obj.startTime, dragStart, dragEnd, 4, realStartLane, realEndLane))
					foundObjects.push(obj);
			}
		}
		
		for (obj in foundObjects)
		{
			if (!state.selectedObjects.value.contains(obj))
				state.selectedObjects.push(obj);
		}
	}
	
	function canSelectObject(startTime:Float, dragStart:Float, dragEnd:Float, lane:Int, startLane:Int, endLane:Int)
	{
		return CoolUtil.inBetween(startTime, dragStart, dragEnd) && CoolUtil.inBetween(lane, startLane, endLane);
	}
}
