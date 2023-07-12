package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
import data.song.EventObject;
import data.song.ITimingObject;
import data.song.LyricStep;
import data.song.ScrollVelocity;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import states.editors.SongEditorState;
import util.editors.song.SongEditorActionManager;

class SongEditorOtherGroup extends FlxBasic
{
	public var timingPoints:Array<SongEditorTimingPoint> = [];
	public var scrollVelocities:Array<SongEditorScrollVelocity> = [];
	public var cameraFocuses:Array<SongEditorCamFocus> = [];
	public var events:Array<SongEditorEvent> = [];
	public var lyricSteps:Array<SongEditorLyricStep> = [];
	
	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var camFocusPool:Array<SongEditorCamFocus>;
	var lastPooledCamFocusIndex:Int = -1;
	var timingPointPool:Array<SongEditorTimingPoint>;
	var lastPooledTimingPointIndex:Int = -1;
	var svPool:Array<SongEditorScrollVelocity>;
	var lastPooledSVIndex:Int = -1;
	var eventPool:Array<SongEditorEvent>;
	var lastPooledEventIndex:Int = -1;
	var lyricStepPool:Array<SongEditorLyricStep>;
	var lastPooledLyricStepIndex:Int = -1;
	
	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		
		for (info in state.song.timingPoints)
			createTimingPoint(info);
		for (info in state.song.scrollVelocities)
			createScrollVelocity(info);
		for (info in state.song.cameraFocuses)
			createCamFocus(info);
		for (info in state.song.events)
			createEvent(info);
		for (info in state.song.lyricSteps)
			createLyricStep(info);
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
		updateSVPool();
		updateCamFocusPool();
		updateEventPool();
		updateLyricStepPool();
	}
	
	override function destroy()
	{
		super.destroy();
		timingPoints = FlxDestroyUtil.destroyArray(timingPoints);
		scrollVelocities = FlxDestroyUtil.destroyArray(scrollVelocities);
		cameraFocuses = FlxDestroyUtil.destroyArray(cameraFocuses);
		events = FlxDestroyUtil.destroyArray(events);
		lyricSteps = FlxDestroyUtil.destroyArray(lyricSteps);
		state = null;
		playfield = null;
		camFocusPool = null;
		timingPointPool = null;
		svPool = null;
		eventPool = null;
		lyricStepPool = null;
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
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
	
	function updateSVPool()
	{
		var i = svPool.length - 1;
		while (i >= 0)
		{
			var obj = svPool[i];
			if (!obj.objectOnScreen())
				svPool.remove(obj);
			i--;
		}
		
		var i = lastPooledSVIndex + 1;
		while (i < scrollVelocities.length)
		{
			var obj = scrollVelocities[i];
			if (obj.objectOnScreen())
			{
				svPool.push(obj);
				lastPooledSVIndex = i;
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
		while (i < cameraFocuses.length)
		{
			var obj = cameraFocuses[i];
			if (obj.objectOnScreen())
			{
				camFocusPool.push(obj);
				lastPooledCamFocusIndex = i;
			}
			i++;
		}
	}
	
	function updateEventPool()
	{
		var i = eventPool.length - 1;
		while (i >= 0)
		{
			var obj = eventPool[i];
			if (!obj.objectOnScreen())
				eventPool.remove(obj);
			i--;
		}
		
		var i = lastPooledEventIndex + 1;
		while (i < events.length)
		{
			var obj = events[i];
			if (obj.objectOnScreen())
			{
				eventPool.push(obj);
				lastPooledEventIndex = i;
			}
			i++;
		}
	}
	
	function updateLyricStepPool()
	{
		var i = lyricStepPool.length - 1;
		while (i >= 0)
		{
			var obj = lyricStepPool[i];
			if (!obj.objectOnScreen())
				lyricStepPool.remove(obj);
			i--;
		}
		
		var i = lastPooledLyricStepIndex + 1;
		while (i < lyricSteps.length)
		{
			var obj = lyricSteps[i];
			if (obj.objectOnScreen())
			{
				lyricStepPool.push(obj);
				lastPooledLyricStepIndex = i;
			}
			i++;
		}
	}
	
	override function draw()
	{
		var pools:Array<Array<ISongEditorTimingObject>> = [
			cast timingPointPool,
			cast svPool,
			cast camFocusPool,
			cast eventPool,
			cast lyricStepPool
		];
		for (pool in pools)
		{
			for (i in 0...pool.length)
			{
				var obj = pool[i];
				if (obj.isOnScreen())
					obj.draw();
			}
		}
	}
	
	public function getHoveredObject():ISongEditorTimingObject
	{
		if (FlxG.mouse.overlaps(state.playfieldTabs))
			return null;
			
		var pools:Array<Array<ISongEditorTimingObject>> = [
			cast timingPointPool,
			cast svPool,
			cast camFocusPool,
			cast eventPool,
			cast lyricStepPool
		];
		for (pool in pools)
		{
			for (obj in pool)
			{
				if (obj.isHovered())
					return obj;
			}
		}
		
		return null;
	}
	
	function createTimingPoint(info:TimingPoint, insertAtIndex:Bool = false)
	{
		var obj = new SongEditorTimingPoint(state, playfield, info);
		timingPoints.push(obj);
		if (insertAtIndex)
			timingPoints.sort(sortObjects);
	}
	
	function createScrollVelocity(info:ScrollVelocity, insertAtIndex:Bool = false)
	{
		var obj = new SongEditorScrollVelocity(state, playfield, info);
		scrollVelocities.push(obj);
		if (insertAtIndex)
			scrollVelocities.sort(sortObjects);
	}
	
	function createCamFocus(info:CameraFocus, insertAtIndex:Bool = false)
	{
		var obj = new SongEditorCamFocus(state, playfield, info);
		cameraFocuses.push(obj);
		if (insertAtIndex)
			cameraFocuses.sort(sortObjects);
	}
	
	function createEvent(info:EventObject, insertAtIndex:Bool = false)
	{
		var obj = new SongEditorEvent(state, playfield, info);
		events.push(obj);
		if (insertAtIndex)
			events.sort(sortObjects);
	}
	
	function createLyricStep(info:LyricStep, insertAtIndex:Bool = false)
	{
		var obj = new SongEditorLyricStep(state, playfield, info);
		lyricSteps.push(obj);
		if (insertAtIndex)
			lyricSteps.sort(sortObjects);
	}
	
	function sortObjects(a:ISongEditorTimingObject, b:ISongEditorTimingObject)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.info.startTime, b.info.startTime);
	}
	
	function initializePools()
	{
		initializeTimingPointPool();
		initializeSVPool();
		initializeCamFocusPool();
		initializeEventPool();
		initializeLyricStepPool();
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
	
	function initializeSVPool()
	{
		svPool = [];
		lastPooledSVIndex = -1;
		
		for (i in 0...scrollVelocities.length)
		{
			var obj = scrollVelocities[i];
			if (!obj.objectOnScreen())
				continue;
			svPool.push(obj);
			lastPooledSVIndex = i;
		}
		
		if (lastPooledSVIndex == -1)
		{
			lastPooledSVIndex = scrollVelocities.length - 1;
			while (lastPooledSVIndex >= 0)
			{
				var obj = scrollVelocities[lastPooledSVIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledSVIndex--;
			}
		}
	}
	
	function initializeCamFocusPool()
	{
		camFocusPool = [];
		lastPooledCamFocusIndex = -1;
		
		for (i in 0...cameraFocuses.length)
		{
			var obj = cameraFocuses[i];
			if (!obj.objectOnScreen())
				continue;
			camFocusPool.push(obj);
			lastPooledCamFocusIndex = i;
		}
		
		if (lastPooledCamFocusIndex == -1)
		{
			lastPooledCamFocusIndex = cameraFocuses.length - 1;
			while (lastPooledCamFocusIndex >= 0)
			{
				var obj = cameraFocuses[lastPooledCamFocusIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledCamFocusIndex--;
			}
		}
	}
	
	function initializeEventPool()
	{
		eventPool = [];
		lastPooledEventIndex = -1;
		
		for (i in 0...events.length)
		{
			var obj = events[i];
			if (!obj.objectOnScreen())
				continue;
			eventPool.push(obj);
			lastPooledEventIndex = i;
		}
		
		if (lastPooledEventIndex == -1)
		{
			lastPooledEventIndex = events.length - 1;
			while (lastPooledEventIndex >= 0)
			{
				var obj = events[lastPooledEventIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledEventIndex--;
			}
		}
	}
	
	function initializeLyricStepPool()
	{
		lyricStepPool = [];
		lastPooledLyricStepIndex = -1;
		
		for (i in 0...lyricSteps.length)
		{
			var obj = lyricSteps[i];
			if (!obj.objectOnScreen())
				continue;
			lyricStepPool.push(obj);
			lastPooledLyricStepIndex = i;
		}
		
		if (lastPooledLyricStepIndex == -1)
		{
			lastPooledLyricStepIndex = lyricSteps.length - 1;
			while (lastPooledLyricStepIndex >= 0)
			{
				var obj = lyricSteps[lastPooledLyricStepIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledLyricStepIndex--;
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
				else if (Std.isOfType(params.object, ScrollVelocity))
				{
					createScrollVelocity(cast params.object, true);
					initializeSVPool();
				}
				else if (Std.isOfType(params.object, CameraFocus))
				{
					createCamFocus(cast params.object, true);
					initializeCamFocusPool();
				}
				else if (Std.isOfType(params.object, EventObject))
				{
					createEvent(cast params.object, true);
					initializeEventPool();
				}
				else if (Std.isOfType(params.object, LyricStep))
				{
					createLyricStep(cast params.object, true);
					initializeLyricStepPool();
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
				else if (Std.isOfType(params.object, ScrollVelocity))
				{
					for (obj in scrollVelocities)
					{
						if (obj.info == params.object)
						{
							scrollVelocities.remove(obj);
							obj.destroy();
							initializeSVPool();
							break;
						}
					}
				}
				else if (Std.isOfType(params.object, CameraFocus))
				{
					for (obj in cameraFocuses)
					{
						if (obj.info == params.object)
						{
							cameraFocuses.remove(obj);
							obj.destroy();
							initializeCamFocusPool();
							break;
						}
					}
				}
				else if (Std.isOfType(params.object, EventObject))
				{
					for (obj in events)
					{
						if (obj.info == params.object)
						{
							events.remove(obj);
							obj.destroy();
							initializeEventPool();
							break;
						}
					}
				}
				else if (Std.isOfType(params.object, LyricStep))
				{
					for (obj in lyricSteps)
					{
						if (obj.info == params.object)
						{
							lyricSteps.remove(obj);
							obj.destroy();
							initializeLyricStepPool();
							break;
						}
					}
				}
			case SongEditorActionManager.ADD_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var addedTimingPoint = false;
				var addedSV = false;
				var addedCamFocus = false;
				var addedEvent = false;
				var addedLyricStep = false;
				for (obj in batch)
				{
					if (Std.isOfType(obj, TimingPoint))
					{
						createTimingPoint(cast obj);
						addedTimingPoint = true;
					}
					else if (Std.isOfType(obj, ScrollVelocity))
					{
						createScrollVelocity(cast obj);
						addedSV = true;
					}
					else if (Std.isOfType(obj, CameraFocus))
					{
						createCamFocus(cast obj);
						addedCamFocus = true;
					}
					else if (Std.isOfType(obj, EventObject))
					{
						createEvent(cast obj);
						addedEvent = true;
					}
					else if (Std.isOfType(obj, LyricStep))
					{
						createLyricStep(cast obj);
						addedLyricStep = true;
					}
				}
				if (addedTimingPoint)
				{
					timingPoints.sort(sortObjects);
					initializeTimingPointPool();
				}
				if (addedSV)
				{
					scrollVelocities.sort(sortObjects);
					initializeSVPool();
				}
				if (addedCamFocus)
				{
					cameraFocuses.sort(sortObjects);
					initializeCamFocusPool();
				}
				if (addedEvent)
				{
					events.sort(sortObjects);
					initializeEventPool();
				}
				if (addedLyricStep)
				{
					lyricSteps.sort(sortObjects);
					initializeLyricStepPool();
				}
			case SongEditorActionManager.REMOVE_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var hasTimingPoint = false;
				var hasSV = false;
				var hasCamFocus = false;
				var hasEvent = false;
				var hasLyricStep = false;
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
				i = scrollVelocities.length - 1;
				while (i >= 0)
				{
					var obj = scrollVelocities[i];
					if (batch.contains(obj.info))
					{
						scrollVelocities.remove(obj);
						obj.destroy();
						hasSV = true;
					}
					i--;
				}
				i = cameraFocuses.length - 1;
				while (i >= 0)
				{
					var obj = cameraFocuses[i];
					if (batch.contains(obj.info))
					{
						cameraFocuses.remove(obj);
						obj.destroy();
						hasCamFocus = true;
					}
					i--;
				}
				i = events.length - 1;
				while (i >= 0)
				{
					var obj = events[i];
					if (batch.contains(obj.info))
					{
						events.remove(obj);
						obj.destroy();
						hasEvent = true;
					}
					i--;
				}
				i = events.length - 1;
				while (i >= 0)
				{
					var obj = events[i];
					if (batch.contains(obj.info))
					{
						events.remove(obj);
						obj.destroy();
						hasEvent = true;
					}
					i--;
				}
				i = lyricSteps.length - 1;
				while (i >= 0)
				{
					var obj = lyricSteps[i];
					if (batch.contains(obj.info))
					{
						lyricSteps.remove(obj);
						obj.destroy();
						hasLyricStep = true;
					}
					i--;
				}
				if (hasTimingPoint)
					initializeTimingPointPool();
				if (hasSV)
					initializeSVPool();
				if (hasCamFocus)
					initializeCamFocusPool();
				if (hasEvent)
					initializeEventPool();
				if (hasLyricStep)
					initializeLyricStepPool();
			case SongEditorActionManager.MOVE_OBJECTS, SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasTimingPoint = false;
				var hasSV = false;
				var hasCamFocus = false;
				var hasEvent = false;
				var hasLyricStep = false;
				for (obj in timingPoints)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasTimingPoint = true;
					}
				}
				for (obj in scrollVelocities)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasSV = true;
					}
				}
				for (obj in cameraFocuses)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasCamFocus = true;
					}
				}
				for (obj in events)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasEvent = true;
					}
				}
				for (obj in lyricSteps)
				{
					if (batch.contains(obj.info))
					{
						obj.updatePosition();
						hasLyricStep = true;
					}
				}
				
				if (hasTimingPoint)
				{
					timingPoints.sort(sortObjects);
					initializeTimingPointPool();
				}
				if (hasSV)
				{
					scrollVelocities.sort(sortObjects);
					initializeSVPool();
				}
				if (hasCamFocus)
				{
					cameraFocuses.sort(sortObjects);
					initializeCamFocusPool();
				}
				if (hasEvent)
				{
					events.sort(sortObjects);
					initializeEventPool();
				}
				if (hasLyricStep)
				{
					lyricSteps.sort(sortObjects);
					initializeLyricStepPool();
				}
			case SongEditorActionManager.CHANGE_TIMING_POINT_TIME:
				for (obj in timingPoints)
				{
					if (params.timingPoints.contains(obj.info))
						obj.updatePosition();
				}
				timingPoints.sort(sortObjects);
				initializeTimingPointPool();
			case SongEditorActionManager.CHANGE_CAMERA_FOCUS_CHAR:
				for (obj in cameraFocuses)
				{
					if (params.cameraFocuses.contains(obj.info))
						obj.updateColor();
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
		else if (Std.isOfType(info, ScrollVelocity))
		{
			for (obj in scrollVelocities)
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
			for (obj in cameraFocuses)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = true;
					break;
				}
			}
		}
		else if (Std.isOfType(info, EventObject))
		{
			for (obj in events)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = true;
					break;
				}
			}
		}
		else if (Std.isOfType(info, LyricStep))
		{
			for (obj in lyricSteps)
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
		else if (Std.isOfType(info, ScrollVelocity))
		{
			for (obj in scrollVelocities)
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
			for (obj in cameraFocuses)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = false;
					break;
				}
			}
		}
		else if (Std.isOfType(info, EventObject))
		{
			for (obj in events)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = false;
					break;
				}
			}
		}
		else if (Std.isOfType(info, LyricStep))
		{
			for (obj in lyricSteps)
			{
				if (obj.info == info)
				{
					obj.selectionSprite.visible = false;
					break;
				}
			}
		}
	}
	
	public function getAllObjects():Array<Array<ISongEditorTimingObject>>
	{
		return [
			cast timingPoints,
			cast scrollVelocities,
			cast cameraFocuses,
			cast events,
			cast lyricSteps
		];
	}
	
	function onMultipleObjectsSelected(array:Array<ITimingObject>)
	{
		for (objects in getAllObjects())
		{
			for (obj in objects)
			{
				if (array.contains(obj.info))
					obj.selectionSprite.visible = true;
			}
		}
	}
	
	function onAllObjectsDeselected()
	{
		for (objects in getAllObjects())
		{
			for (obj in objects)
				obj.selectionSprite.visible = false;
		}
	}
	
	function refreshPositions()
	{
		for (objects in getAllObjects())
		{
			for (obj in objects)
				obj.updatePosition();
		}
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
	
	override function isOnScreen(?camera:FlxCamera)
	{
		return super.isOnScreen(camera);
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

class SongEditorScrollVelocity extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;
	
	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	
	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:ScrollVelocity)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		
		line = new FlxSprite().makeGraphic(Std.int(playfield.columnSize - playfield.borderLeft.width), 10, 0xFF56FE6E);
		add(line);
		
		selectionSprite = new FlxSprite(0, -10).makeGraphic(Std.int(line.width), Std.int(line.height + 20));
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);
		
		updatePosition();
	}
	
	override function isOnScreen(?camera:FlxCamera)
	{
		return super.isOnScreen(camera);
	}
	
	public function updatePosition()
	{
		x = playfield.bg.x + playfield.columnSize * 1 + playfield.borderLeft.width;
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
	
	override function isOnScreen(?camera:FlxCamera)
	{
		return super.isOnScreen(camera);
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

class SongEditorEvent extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;
	
	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	
	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:EventObject)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		
		line = new FlxSprite().makeGraphic(Std.int(playfield.columnSize - playfield.borderLeft.width), 10, 0xFFB4B4B4);
		add(line);
		
		selectionSprite = new FlxSprite(0, -10).makeGraphic(Std.int(line.width), Std.int(line.height + 20));
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);
		
		updatePosition();
	}
	
	override function isOnScreen(?camera:FlxCamera)
	{
		return super.isOnScreen(camera);
	}
	
	public function updatePosition()
	{
		x = playfield.bg.x + playfield.columnSize * 3 + playfield.borderLeft.width;
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

class SongEditorLyricStep extends FlxSpriteGroup implements ISongEditorTimingObject
{
	public var info:ITimingObject;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;
	
	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	
	public function new(state:SongEditorState, playfield:SongEditorPlayfield, info:LyricStep)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.info = info;
		
		line = new FlxSprite().makeGraphic(Std.int(playfield.columnSize - playfield.borderLeft.width), 10, FlxColor.YELLOW);
		add(line);
		
		selectionSprite = new FlxSprite(0, -10).makeGraphic(Std.int(line.width), Std.int(line.height + 20));
		selectionSprite.alpha = 0.5;
		selectionSprite.visible = false;
		add(selectionSprite);
		
		updatePosition();
	}
	
	override function isOnScreen(?camera:FlxCamera)
	{
		return super.isOnScreen(camera);
	}
	
	public function updatePosition()
	{
		x = playfield.bg.x + playfield.columnSize * 4 + playfield.borderLeft.width;
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
