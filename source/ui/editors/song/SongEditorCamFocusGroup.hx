package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
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

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;
		for (info in state.song.cameraFocuses)
			createCamFocus(info);

		state.rateChanged.add(onRateChanged);
		state.actionManager.onEvent.add(onEvent);
		state.selectedCamFocuses.itemAdded.add(onSelectedCameraFocus);
		state.selectedCamFocuses.itemRemoved.add(onDeselectedCameraFocus);
		state.selectedCamFocuses.multipleItemsAdded.add(onMultipleCameraFocusesSelected);
		state.selectedCamFocuses.arrayCleared.add(onAllCameraFocusesDeselected);
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
		for (camFocus in camFocuses)
		{
			if (camFocus.isHovered())
				return camFocus;
		}

		return null;
	}

	function createCamFocus(info:CameraFocus, insertAtIndex:Bool = false)
	{
		var camFocus = new SongEditorCamFocus(state, info);
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
			case SongEditorActionManager.ADD_CAMERA_FOCUS:
				createCamFocus(params.camFocus, true);
			case SongEditorActionManager.REMOVE_CAMERA_FOCUS:
				for (camFocus in camFocuses)
				{
					if (camFocus.info == params.camFocus)
					{
						camFocuses.remove(camFocus);
						camFocus.destroy();
						break;
					}
				}
			case SongEditorActionManager.ADD_CAMERA_FOCUS_BATCH:
				var batch:Array<CameraFocus> = params.camFocuses;
				for (camFocus in batch)
					createCamFocus(camFocus);
				camFocuses.sort(sortCamFocuses);
			case SongEditorActionManager.REMOVE_CAMERA_FOCUS_BATCH:
				var batch:Array<CameraFocus> = params.camFocuses;
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
				if (params.camFocuses != null)
				{
					var batch:Array<CameraFocus> = params.camFocuses;
					for (camFocus in camFocuses)
					{
						if (batch.contains(camFocus.info))
							camFocus.updatePosition();
					}
				}
		}
	}

	function onSelectedCameraFocus(info:CameraFocus)
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

	function onDeselectedCameraFocus(info:CameraFocus)
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

	function onMultipleCameraFocusesSelected(array:Array<CameraFocus>)
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

class SongEditorCamFocus extends FlxSpriteGroup
{
	public var info:CameraFocus;
	public var line:FlxSprite;
	public var selectionSprite:FlxSprite;

	var state:SongEditorState;

	public function new(state:SongEditorState, info:CameraFocus)
	{
		super();
		this.state = state;
		this.info = info;

		line = new FlxSprite().makeGraphic(state.columnSize - 2, 10);
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
		x = state.playfieldBG.x + state.columnSize * 8 + 2;
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
		return switch (info.char)
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
