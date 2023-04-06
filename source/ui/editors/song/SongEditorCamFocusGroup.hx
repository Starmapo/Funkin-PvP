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

	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		for (info in state.song.cameraFocuses)
			createCamFocus(info);

		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedObjects.itemAdded.add(onSelectedCameraFocus);
		state.selectedObjects.itemRemoved.add(onDeselectedCameraFocus);
		state.selectedObjects.multipleItemsAdded.add(onMultipleCameraFocusesSelected);
		state.selectedObjects.arrayCleared.add(onAllCameraFocusesDeselected);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function draw()
	{
		for (i in 0...camFocuses.length)
		{
			var camFocus = camFocuses[i];
			if (camFocus.isOnScreen())
				camFocus.draw();
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
					createCamFocus(cast params.object, true);
			case SongEditorActionManager.REMOVE_OBJECT:
				if (Std.isOfType(params.object, CameraFocus))
				{
					for (camFocus in camFocuses)
					{
						if (camFocus.info == params.object)
						{
							camFocuses.remove(camFocus);
							camFocus.destroy();
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
					camFocuses.sort(sortCamFocuses);
			case SongEditorActionManager.REMOVE_OBJECT_BATCH:
				var batch:Array<ITimingObject> = params.objects;
				var i = camFocuses.length - 1;
				while (i >= 0)
				{
					var camFocus = camFocuses[i];
					if (batch.contains(camFocus.info))
					{
						camFocuses.remove(camFocus);
						camFocus.destroy();
					}
					i--;
				}
			case SongEditorActionManager.MOVE_OBJECTS, SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				for (camFocus in camFocuses)
				{
					if (batch.contains(camFocus.info))
						camFocus.updatePosition();
				}
		}
	}

	function onSelectedCameraFocus(info:ITimingObject)
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

	function onDeselectedCameraFocus(info:ITimingObject)
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
