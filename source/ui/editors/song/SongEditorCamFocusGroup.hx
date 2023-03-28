package ui.editors.song;

import data.Settings;
import data.song.CameraFocus;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import states.editors.SongEditorState;

class SongEditorCamFocusGroup extends FlxBasic
{
	var camFocuses:Array<SongEditorCamFocus> = [];
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;
		for (info in state.song.cameraFocuses)
			createCamFocus(info);

		state.rateChanged.add(onRateChanged);
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

	function createCamFocus(info:CameraFocus, insertAtIndex:Bool = false)
	{
		var camFocus = new SongEditorCamFocus(state, info);
		camFocuses.push(camFocus);
		if (insertAtIndex)
			camFocuses.sort(sortNotes);
	}

	function sortNotes(a:SongEditorCamFocus, b:SongEditorCamFocus)
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

	function refreshPositions()
	{
		for (camFocus in camFocuses)
			camFocus.updatePosition();
	}
}

class SongEditorCamFocus extends FlxSprite
{
	public var info:CameraFocus;

	var state:SongEditorState;

	public function new(state:SongEditorState, info:CameraFocus)
	{
		super();
		this.state = state;
		this.info = info;

		makeGraphic(state.columnSize - 2, 10);
		updatePosition();
		updateColor();
	}

	public function updatePosition()
	{
		x = state.playfieldBG.x + state.columnSize * 8 + 2;
		y = state.hitPositionY - info.startTime * state.trackSpeed - height;
	}

	public function updateColor()
	{
		color = getColor();
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
