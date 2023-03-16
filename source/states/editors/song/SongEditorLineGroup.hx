package states.editors.song;

import data.song.SliderVelocity;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class SongEditorLineGroup extends FlxBasic
{
	var state:SongEditorState;
	var lines:Array<SongEditorLine> = [];
	var linePool:Array<SongEditorLine> = [];
	var lastPooledLineIndex:Int = -1;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		initializeTicks();
		state.songSeeked.add(onSongSeeked);
	}

	override function update(elapsed:Float)
	{
		var i = linePool.length - 1;
		while (i >= 0)
		{
			var line = linePool[i];
			if (!line.lineOnScreen())
				linePool.remove(line);
			i--;
		}

		i = lastPooledLineIndex + 1;
		while (i < lines.length)
		{
			var line = lines[i];
			if (line.lineOnScreen())
			{
				linePool.push(line);
				lastPooledLineIndex = i;
			}
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...linePool.length)
		{
			var line = linePool[i];
			if (!line.lineOnScreen())
				continue;
			line.updatePosition();
			line.updateSize();
			line.cameras = cameras;
			line.draw();
		}
	}

	override function destroy()
	{
		for (line in lines)
			line.destroy();
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
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

		initializeLinePool();
	}

	function initializeLinePool()
	{
		linePool = [];
		lastPooledLineIndex = -1;
		for (i in 0...lines.length)
		{
			var line = lines[i];
			if (!line.lineOnScreen())
				continue;
			linePool.push(line);
			lastPooledLineIndex = i;
		}

		if (lastPooledLineIndex == -1)
		{
			lastPooledLineIndex = lines.length - 1;
			while (lastPooledLineIndex >= 0)
			{
				if (lines[lastPooledLineIndex].getTime() < state.inst.time)
					break;

				lastPooledLineIndex--;
			}
		}
	}

	function onSongSeeked(_, _)
	{
		initializeLinePool();
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
		updateSize();
	}

	public function updatePosition()
	{
		var x = state.playfieldBG.x + state.playfieldBG.width + 2;
		var y = state.hitPositionY - getTime() * state.trackSpeed - height;

		if (this.x != x || this.y != y)
			setPosition(x, y);
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
