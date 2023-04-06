package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
import data.song.ITimingObject;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import states.editors.SongEditorState;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorCamFocusGroup extends FlxBasic
{
	public var camFocuses:Array<SongEditorCamFocus> = [];

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var objectPool:Array<SongEditorCamFocus>;
	var lastPooledObjectIndex:Int = -1;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;

		for (info in state.song.cameraFocuses)
			createCamFocus(info);
		initializeObjectPool();

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedCameraFocus);
		state.selectedObjects.itemRemoved.add(onDeselectedCameraFocus);
		state.selectedObjects.multipleItemsAdded.add(onMultipleCameraFocusesSelected);
		state.selectedObjects.arrayCleared.add(onAllCameraFocusesDeselected);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function update(elapsed:Float)
	{
		var i = objectPool.length - 1;
		while (i >= 0)
		{
			var obj = objectPool[i];
			if (!obj.objectOnScreen())
				objectPool.remove(obj);
			i--;
		}

		var i = lastPooledObjectIndex + 1;
		while (i < camFocuses.length)
		{
			var obj = camFocuses[i];
			if (obj.objectOnScreen())
			{
				objectPool.push(obj);
				lastPooledObjectIndex = i;
			}
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...objectPool.length)
		{
			var obj = objectPool[i];
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

	public function getHoveredCamFocus()
	{
		if (FlxG.mouse.overlaps(state.playfieldTabs))
			return null;

		for (camFocus in camFocuses)
		{
			if (camFocus.isHovered())
				return camFocus;
		}

		return null;
	}

	function createCamFocus(info:CameraFocus, insertAtIndex:Bool = false)
	{
		var camFocus = new SongEditorCamFocus(state, playfield, info);
		camFocuses.push(camFocus);
		if (insertAtIndex)
			camFocuses.sort(sortCamFocuses);
	}

	function sortCamFocuses(a:SongEditorCamFocus, b:SongEditorCamFocus)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a.info.startTime, b.info.startTime);
	}

	function initializeObjectPool()
	{
		objectPool = [];
		lastPooledObjectIndex = -1;

		for (i in 0...camFocuses.length)
		{
			var obj = camFocuses[i];
			if (!obj.objectOnScreen())
				continue;
			objectPool.push(obj);
			lastPooledObjectIndex = i;
		}

		if (lastPooledObjectIndex == -1)
		{
			lastPooledObjectIndex = camFocuses.length - 1;
			while (lastPooledObjectIndex >= 0)
			{
				var obj = camFocuses[lastPooledObjectIndex];
				if (obj.info.startTime < state.inst.time)
					break;
				lastPooledObjectIndex--;
			}
		}
	}

	function onSongSeeked(_, _)
	{
		initializeObjectPool();
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
				if (Std.isOfType(params.object, CameraFocus))
				{
					createCamFocus(cast params.object, true);
					initializeObjectPool();
				}
			case SongEditorActionManager.REMOVE_OBJECT:
				if (Std.isOfType(params.object, CameraFocus))
				{
					for (camFocus in camFocuses)
					{
						if (camFocus.info == params.object)
						{
							camFocuses.remove(camFocus);
							camFocus.destroy();
							initializeObjectPool();
							break;
						}
					}
				}
			case SongEditorActionManager.ADD_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var added = false;
				for (obj in batch)
				{
					if (Std.isOfType(obj, CameraFocus))
					{
						createCamFocus(cast obj);
						added = true;
					}
				}
				if (added)
				{
					camFocuses.sort(sortCamFocuses);
					initializeObjectPool();
				}
			case SongEditorActionManager.REMOVE_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var hasObject = false;
				var i = camFocuses.length - 1;
				while (i >= 0)
				{
					var camFocus = camFocuses[i];
					if (batch.contains(camFocus.info))
					{
						camFocuses.remove(camFocus);
						camFocus.destroy();
						hasObject = true;
					}
					i--;
				}
				if (hasObject)
					initializeObjectPool();
			case SongEditorActionManager.MOVE_OBJECTS, SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasCamFocus = false;
				for (camFocus in camFocuses)
				{
					if (batch.contains(camFocus.info))
					{
						camFocus.updatePosition();
						hasCamFocus = true;
					}
				}
				if (hasCamFocus)
				{
					camFocuses.sort(sortCamFocuses);
					initializeObjectPool();
				}
		}
	}

	function onSelectedCameraFocus(info:ITimingObject)
	{
		if (Std.isOfType(info, CameraFocus))
		{
			for (camFocus in camFocuses)
			{
				if (camFocus.info == info)
				{
					camFocus.selectionSprite.visible = true;
					break;
				}
			}
		}
	}

	function onDeselectedCameraFocus(info:ITimingObject)
	{
		if (Std.isOfType(info, CameraFocus))
		{
			for (camFocus in camFocuses)
			{
				if (camFocus.info == info)
				{
					camFocus.selectionSprite.visible = false;
					break;
				}
			}
		}
	}

	function onMultipleCameraFocusesSelected(array:Array<ITimingObject>)
	{
		for (camFocus in camFocuses)
		{
			if (array.contains(camFocus.info))
				camFocus.selectionSprite.visible = true;
		}
	}

	function onAllCameraFocusesDeselected()
	{
		for (camFocus in camFocuses)
			camFocus.selectionSprite.visible = false;
	}

	function refreshPositions()
	{
		for (camFocus in camFocuses)
			camFocus.updatePosition();
		initializeObjectPool();
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
