package states.editors.song;

import data.Settings;
import data.song.SliderVelocity;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class SongEditorLineGroup extends FlxBasic
{
	var state:SongEditorState;
	var lines:Array<SongEditorLine> = [];

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		initializeTicks();

		state.rateChanged.add(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function draw()
	{
		var drewLine = false;
		for (i in 0...lines.length)
		{
			var line = lines[i];
			if (line.isOnScreen())
			{
				line.draw();
				drewLine = true;
			}
			else if (drewLine)
				break;
		}
	}

	override function destroy()
	{
		for (line in lines)
			line.destroy();
		super.destroy();

		state.rateChanged.remove(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
	}

	function initializeTicks()
	{
		lines = [];
		var timingPointIndex = 0;
		var svIndex = 0;
		while (lines.length != state.song.timingPoints.length + state.song.sliderVelocities.length)
		{
			var pointExists = timingPointIndex < state.song.timingPoints.length;
			var svExists = svIndex < state.song.sliderVelocities.length;

			if (pointExists && svExists)
			{
				if (state.song.timingPoints[timingPointIndex].startTime < state.song.sliderVelocities[svIndex].startTime)
				{
					lines.push(new SongEditorLine(state, TIMING_POINT, state.song.timingPoints[timingPointIndex]));
					timingPointIndex++;
				}
				else
				{
					lines.push(new SongEditorLine(state, SCROLL_VELOCITY, state.song.sliderVelocities[svIndex]));
					svIndex++;
				}
			}
			else if (pointExists)
			{
				lines.push(new SongEditorLine(state, TIMING_POINT, state.song.timingPoints[timingPointIndex]));
				timingPointIndex++;
			}
			else if (svExists)
			{
				lines.push(new SongEditorLine(state, SCROLL_VELOCITY, state.song.sliderVelocities[svIndex]));
				svIndex++;
			}
		}
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshLines();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshLines();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		if (state.inst.pitch != 1)
			refreshLines();
	}

	function refreshLines()
	{
		for (line in lines)
		{
			line.updatePosition();
		}
	}
}

class SongEditorLine extends FlxSprite
{
	var state:SongEditorState;
	var type:LineType;
	var timingPoint:TimingPoint;
	var scrollVelocity:SliderVelocity;

	public function new(state:SongEditorState, type:LineType, data:Dynamic)
	{
		super();
		this.state = state;
		this.type = type;
		switch (type)
		{
			case TIMING_POINT:
				timingPoint = cast data;
			case SCROLL_VELOCITY:
				scrollVelocity = cast data;
		}
		makeGraphic(1, 1, getColor());
		updatePosition();
		updateSize();
	}

	public function updatePosition()
	{
		x = state.playfieldBG.x + state.playfieldBG.width + 2;
		y = state.hitPositionY - getTime() * state.trackSpeed - height;
	}

	public function updateSize()
	{
		var defaultWidth = 40;
		var defaultHeight = 2;
		switch (type)
		{
			case TIMING_POINT:
				setGraphicSize(defaultWidth, 4);
			case SCROLL_VELOCITY:
				var size = FlxMath.boundInt(Std.int(40 * Math.abs(scrollVelocity.multiplier)), 10, 150);
				setGraphicSize(size, defaultHeight);
		}
		updateHitbox();
	}

	public function lineOnScreen()
	{
		return getTime() * state.trackSpeed >= state.trackPositionY - state.playfieldBG.height
			&& getTime() * state.trackSpeed <= state.trackPositionY + state.playfieldBG.height;
	}

	public function getTime()
	{
		return switch (type)
		{
			case TIMING_POINT:
				Math.round(timingPoint.startTime);
			case SCROLL_VELOCITY:
				Math.round(scrollVelocity.startTime);
		}
	}

	public function getColor()
	{
		return switch (type)
		{
			case TIMING_POINT:
				0xFFFE5656;
			case SCROLL_VELOCITY:
				0xFF56FE6E;
		}
	}
}

enum LineType
{
	TIMING_POINT;
	SCROLL_VELOCITY;
}
