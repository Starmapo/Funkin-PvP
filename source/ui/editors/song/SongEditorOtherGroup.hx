package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
import data.song.ITimingObject;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import states.editors.SongEditorState;
import util.editors.song.SongEditorActionManager;

class SongEditorOtherGroup extends FlxBasic
{
	public var timingPoints:Array<SongEditorTimingPoint> = [];
	public var camFocuses:Array<SongEditorCamFocus> = [];

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var camFocusPool:Array<SongEditorCamFocus>;
	var lastPooledCamFocusIndex:Int = -1;
	var timingPointPool:Array<SongEditorTimingPoint>;
	var lastPooledTimingPointIndex:Int = -1;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;

		for (info in state.song.timingPoints)
			createTimingPoint(info);
		for (info in state.song.cameraFocuses)
			createCamFocus(info);
		initializePools();

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedObject);
		state.selectedObjects.itemRemoved.add(onDeselectedObject);
		state.selectedObjects.multipleItemsAdded.add(onMultipleObjectsSelected);
		state.selectedObjects.arrayCleared.add(onAllObjectsDeselected);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function update(elapsed:Float)
	{
		updateTimingPointPool();
		updateCamFocusPool();
	}

	function updateTimingPointPool()
	{
		var i = timingPointPool.length - 1;
		while (i >= 0)
		{
			var obj = timingPointPool[i];
			if (!obj.objectOnScreen())
				timingPointPool.remove(obj);
			i--;
		}

		var i = lastPooledTimingPointIndex + 1;
		while (i < timingPoints.length)
		{
			var obj = timingPoints[i];
			if (obj.objectOnScreen())
			{
				timingPointPool.push(obj);
				lastPooledTimingPointIndex = i;
			}
			i++;
		}
	}

	function updateCamFocusPool()
	{
		var i = camFocusPool.length - 1;
		while (i >= 0)
		{
			var obj = camFocusPool[i];
			if (!obj.objectOnScreen())
				camFocusPool.remove(obj);
			i--;
		}

		var i = lastPooledCamFocusIndex + 1;
		while (i < camFocuses.length)
		{
			var obj = camFocuses[i];
			if (obj.objectOnScreen())
			{
				camFocusPool.push(obj);
				lastPooledCamFocusIndex = i;
			}
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...timingPointPool.length)
		{
			var obj = timingPointPool[i];
			if (obj.isOnScreen())
				obj.draw();
		}
		for (i in 0...camFocusPool.length)
		{
			var obj = camFocusPool[i];
			if (obj.isOnScreen())
				obj.draw();
		}
	}

	override function destroy()
	{
		state.rateChanged.add(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
		super.destroy();
	}

	public function getHoveredObject():ISongEditorTimingObject
	{
		if (FlxG.mouse.overlaps(state.playfieldTabs))
			return null;

		for (timingPoint in timingPointPool)
		{
			if (timingPoint.isHovered())
				return timingPoint;
		}
		for (camFocus in camFocusPool)
		{
			if (camFocus.isHovered())
				return camFocus;
		}

		return null;
	}

	function createTimingPoint(info:TimingPoint, insertAtIndex:Bool = false)
	{
		var timingPoint = new SongEditorTimingPoint(state, playfield, info);
		timingPoints.push(timingPoint);
		if (insertAtIndex)
			timingPoints.sort(sortObjects);
	}

	function createCamFocus(info:CameraFocus, insertAtIndex:Bool = false)
	{
		var camFocus = new SongEditorCamFocus(state, playfield, info);
		camFocuses.push(camFocus);
		if (insertAtIndex)
			camFocuses.sort(sortObjects);
	}

	function sortObjects(a:ISongEditorTimingObject, b:ISongEditorTimingObject)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.info.startTime, b.info.startTime);
	}

	function initializePools()
	{
		initializeTimingPointPool();
		initializeCamFocusPool();
	}

	function initializeTimingPointPool()
	{
		timingPointPool = [];
		lastPooledTimingPointIndex = -1;

		for (i in 0...timingPoints.length)
		{
			var obj = timingPoints[i];
			if (!obj.objectOnScreen())
				continue;
			timingPointPool.push(obj);
			lastPooledTimingPointIndex = i;
		}

		if (lastPooledTimingPointIndex == -1)
		{
			lastPooledTimingPointIndex = timingPoints.length - 1;
			while (lastPooledTimingPointIndex >= 0)
			{
				var obj = timingPoints[lastPooledTimingPointIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledTimingPointIndex--;
			}
		}
	}

	function initializeCamFocusPool()
	{
		camFocusPool = [];
		lastPooledCamFocusIndex = -1;

		for (i in 0...camFocuses.length)
		{
			var obj = camFocuses[i];
			if (!obj.objectOnScreen())
				continue;
			camFocusPool.push(obj);
			lastPooledCamFocusIndex = i;
		}

		if (lastPooledCamFocusIndex == -1)
		{
			lastPooledCamFocusIndex = camFocuses.length - 1;
			while (lastPooledCamFocusIndex >= 0)
			{
				var obj = camFocuses[lastPooledCamFocusIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledCamFocusIndex--;
			}
		}
	}

	function onSongSeeked(_, _)
	{
		initializePools();
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshPositions();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshPositions();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		if (state.inst.pitch != 1)
			refreshPositions();
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_OBJECT:
				if (Std.isOfType(params.object, TimingPoint))
				{
					createTimingPoint(cast params.object, true);
					initializeTimingPointPool();
				}
				else if (Std.isOfType(params.object, CameraFocus))
				{
					createCamFocus(cast params.object, true);
					initializeCamFocusPool();
				}
			case SongEditorActionManager.REMOVE_OBJECT:
				if (Std.isOfType(params.object, TimingPoint))
				{
					for (obj in timingPoints)
					{
						if (obj.info == params.object)
						{
							timingPoints.remove(obj);
							obj.destroy();
							initializeTimingPointPool();
							break;
						}
					}
				}
				else if (Std.isOfType(params.object, CameraFocus))
				{
					for (obj in camFocuses)
					{
						if (obj.info == params.object)
						{
							camFocuses.remove(obj);
							obj.destroy();
							initializeCamFocusPool();
							break;
						}
					}
				}
			case SongEditorActionManager.ADD_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var addedTimingPoint = false;
				var addedCamFocus = false;
				for (obj in batch)
				{
					if (Std.isOfType(obj, TimingPoint))
					{
						createTimingPoint(cast obj);
						addedTimingPoint = true;
					}
					else if (Std.isOfType(obj, CameraFocus))
					{
						createCamFocus(cast obj);
						addedCamFocus = true;
					}
				}
				if (addedTimingPoint)
				{
					timingPoints.sort(sortObjects);
					initializeTimingPointPool();
				}
				if (addedCamFocus)
				{
					camFocuses.sort(sortObjects);
					initializeCamFocusPool();
				}
			case SongEditorActionManager.REMOVE_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var hasTimingPoint = false;
				var hasCamFocus = false;
				var i = timingPoints.length - 1;
				while (i >= 0)
				{
					var obj = timingPoints[i];
					if (batch.contains(obj.info))
					{
						timingPoints.remove(obj);
						obj.destroy();
						hasTimingPoint = true;
					}
					i--;
				}
				i = camFocuses.length - 1;
				while (i >= 0)
				{
					var obj = camFocuses[i];
					if (batch.contains(obj.info))
					{
						camFocuses.remove(obj);
						obj.destroy();
						hasCamFocus = true;
					}
					i--;
				}
				if (hasTimingPoint)
					initializeTimingPointPool();
				if (hasCamFocus)
					initializeCamFocusPool();
			case SongEditorActionManager.MOVE_OBJECTS, SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasTimingPoint = false;
				var hasCamFocus = false;
				for (obj in timingPoints)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasTimingPoint = true;
					}
				}
				for (obj in camFocuses)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasCamFocus = true;
					}
				}
				if (hasTimingPoint)
				{
					timingPoints.sort(sortObjects);
					initializeTimingPointPool();
				}
				if (hasCamFocus)
				{
					camFocuses.sort(sortObjects);
					initializeCamFocusPool();
				}
		}
	}

	function onSelectedObject(info:ITimingObject)
	{
		if (Std.isOfType(info, TimingPoint))
		{
			for (obj in timingPoints)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = true;
					break;
				}
			}
		}
		else if (Std.isOfType(info, CameraFocus))
		{
			for (obj in camFocuses)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = true;
					break;
				}
			}
		}
	}

	function onDeselectedObject(info:ITimingObject)
	{
		if (Std.isOfType(info, CameraFocus))
		{
			for (obj in timingPoints)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = false;
					break;
				}
			}
		}
		else if (Std.isOfType(info, CameraFocus))
		{
			for (obj in camFocuses)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = false;
					break;
				}
			}
		}
	}

	function onMultipleObjectsSelected(array:Array<ITimingObject>)
	{
		for (obj in timingPoints)
		{
			if (array.contains(obj.info))
				obj.selectionSprite.visible = true;
		}
		for (obj in camFocuses)
		{
			if (array.contains(obj.info))
				obj.selectionSprite.visible = true;
		}
	}

	function onAllObjectsDeselected()
	{
		for (obj in timingPoints)
			obj.selectionSprite.visible = false;
		for (obj in camFocuses)
			obj.selectionSprite.visible = false;
	}

	function refreshPositions()
	{
		for (obj in timingPoints)
			obj.updatePosition();
		for (obj in camFocuses)
			obj.updatePosition();
		initializePools();
	}
}

class SongEditorTimingPoint extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var timingPointInfo:TimingPoint;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:TimingPoint)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		timingPointInfo = info;

		line = new FlxSprite().makeGraphic(Std.int(playfield.columnSize - playfield.borderLeft.width), 10, 0xFFFE5656);
		add(line);

		selectionSprite = new FlxSprite(0, -10).makeGraphic(Std.int(line.width), Std.int(line.height + 20));
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);

		updatePosition();
	}

	public function updatePosition()
	{
		x = playfield.bg.x + playfield.borderLeft.width;
		y = state.hitPositionY - info.startTime * state.trackSpeed - line.height;
	}

	public function isHovered()
	{
		return FlxG.mouse.overlaps(line);
	}

	public function objectOnScreen()
	{
		return info.startTime * state.trackSpeed >= state.trackPositionY - playfield.bg.height
			&& info.startTime * state.trackSpeed <= state.trackPositionY + playfield.bg.height;
	}
}

class SongEditorCamFocus extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var camFocusInfo:CameraFocus;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:CameraFocus)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		camFocusInfo = info;

		line = new FlxSprite().makeGraphic(Std.int(playfield.columnSize - playfield.borderLeft.width), 10);
		add(line);

		selectionSprite = new FlxSprite(0, -10).makeGraphic(Std.int(line.width), Std.int(line.height + 20));
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);

		updatePosition();
		updateColor();
	}

	public function updatePosition()
	{
		x = playfield.bg.x + playfield.columnSize * 2 + playfield.borderLeft.width;
		y = state.hitPositionY - info.startTime * state.trackSpeed - line.height;
	}

	public function updateColor()
	{
		line.color = getColor();
	}

	public function isHovered()
	{
		return FlxG.mouse.overlaps(line);
	}

	public function objectOnScreen()
	{
		return info.startTime * state.trackSpeed >= state.trackPositionY - playfield.bg.height
			&& info.startTime * state.trackSpeed <= state.trackPositionY + playfield.bg.height;
	}

	function getColor()
	{
		return switch (camFocusInfo.char)
		{
			case OPPONENT:
				0xFF8E00CC;
			case BF:
				0xFF00A5CE;
			case GF:
				0xFFA5004D;
		}
	}
}
