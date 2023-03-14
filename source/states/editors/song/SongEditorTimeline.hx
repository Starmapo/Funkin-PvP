package states.editors.song;

import data.Settings;
import data.song.TimingPoint;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

class SongEditorTimeline extends FlxTypedGroup<SongEditorTimelineTick>
{
	public var lines:Array<SongEditorTimelineTick>;
	public var linePool:Array<SongEditorTimelineTick>;

	var state:SongEditorState;
	var cachedLines:Map<Int, Array<SongEditorTimelineTick>> = new Map();
	var lastPooledLineIndex:Int = -1;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		initializeLines();

		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
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
			if (!line.lineOnScreen())
				break;
			linePool.push(line);
			lastPooledLineIndex = i;
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...linePool.length)
		{
			var line = linePool[i];
			line.updatePosition();
			line.updateColor();
			if (line.lineOnScreen())
			{
				line.cameras = cameras;
				line.draw();
			}
		}
	}

	override function destroy()
	{
		super.destroy();
		for (lines in cachedLines)
		{
			for (line in lines)
				FlxDestroyUtil.destroy(line);
		}
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
	}

	public function initializeLines(forceRefresh:Bool = false)
	{
		if (cachedLines.exists(state.beatSnap.value) && !forceRefresh)
		{
			lines = cachedLines.get(state.beatSnap.value);
			return;
		}

		var newLines:Array<SongEditorTimelineTick> = [];
		var measureCount = 0;
		for (point in state.song.timingPoints)
		{
			if (point.startTime > state.inst.length)
				continue;

			if (!Math.isFinite(point.bpm))
				continue;

			var pointLength = state.song.getTimingPointLength(point);
			var startTime = point.startTime;
			var numBeatsOffsetted = 0;

			if (point == state.song.timingPoints[0] && startTime > 0)
			{
				while (true)
				{
					if (numBeatsOffsetted / state.beatSnap.value % point.meter == 0
						&& numBeatsOffsetted % state.beatSnap.value == 0
						&& startTime <= -2000)
						break;

					numBeatsOffsetted++;
					startTime -= point.beatLength;
					pointLength += point.beatLength;
				}
			}

			if (point == state.song.timingPoints[state.song.timingPoints.length - 1])
				pointLength = state.inst.length + point.beatLength * numBeatsOffsetted + 2000;

			trace(pointLength, point.beatLength);

			var i = 0;
			while (i < pointLength / point.beatLength * state.beatSnap.value)
			{
				var time = startTime + point.beatLength / state.beatSnap.value * i;
				var measureBeat = i / state.beatSnap.value % point.meter == 0 && i % state.beatSnap.value == 0;

				if (measureBeat && time >= point.startTime)
					measureCount++;

				var line = new SongEditorTimelineTick(state, point, time, i, measureCount, measureBeat);
				newLines.push(line);

				i++;
			}
		}

		cachedLines.set(state.beatSnap.value, newLines);
		lines = newLines;
		initializeLinePool();
	}

	public function onBeatSnapChanged()
	{
		initializeLines();
	}

	public function onScrollSpeedChanged()
	{
		refreshLines();
	}

	public function onScaleSpeedWithRateChanged(_, _)
	{
		refreshLines();
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
	}

	function reinitialize()
	{
		for (lines in cachedLines)
		{
			for (line in lines)
				FlxDestroyUtil.destroy(line);
		}

		lines.resize(0);
		cachedLines.clear();

		initializeLines();
	}

	function refreshLines()
	{
		for (line in lines)
			line.setPosition();

		initializeLinePool();
	}
}

class SongEditorTimelineTick extends FlxSpriteGroup
{
	var state:SongEditorState;
	var timingPoint:TimingPoint;
	var time:Float;
	var index:Int;
	var measureCount:Int;
	var isMeasureLine:Bool;
	var line:FlxSprite;
	var measureText:FlxText;

	public function new(state:SongEditorState, timingPoint:TimingPoint, time:Float, index:Int, measureCount:Int, isMeasureLine:Bool)
	{
		super();
		this.state = state;
		this.timingPoint = timingPoint;
		this.time = time;
		this.index = index;
		this.measureCount = measureCount;
		this.isMeasureLine = isMeasureLine;

		var height = (isMeasureLine && time >= timingPoint.startTime) ? 5 : 2;

		line = new FlxSprite(0, 0).makeGraphic(Std.int(state.playfieldBG.width - 4), height);
		updateColor();
		add(line);

		if (!isMeasureLine)
		{
			updatePosition();
			return;
		}

		line.y -= 2;

		measureText = new FlxText(0, 0, 0, Std.string(measureCount), 24);
		measureText.x = -measureText.width - 16;
		measureText.y -= measureText.height / 2;
		add(measureText);

		updatePosition();
	}

	public function updatePosition()
	{
		setPosition(state.playfieldBG.x + 2, state.hitPositionY - time * state.trackSpeed - height);
	}

	public function updateColor()
	{
		line.color = getLineColor(index % state.beatSnap.value, index);
	}

	public function lineOnScreen()
	{
		return time * state.trackSpeed >= state.trackPositionY - state.playfieldBG.height
			&& time * state.trackSpeed <= state.trackPositionY + state.playfieldBG.height;
	}

	function getLineColor(val:Int, i:Int)
	{
		switch (state.beatSnap.value)
		{
			case 1:
				return FlxColor.WHITE;
			case 2:
				switch (val)
				{
					case 0:
						return FlxColor.WHITE;
					default:
						return FlxColor.RED;
				}
			case 4:
				switch (val)
				{
					case 0, 4:
						return FlxColor.WHITE;
					case 1, 3:
						return 0xFF0085ff;
					default:
						return FlxColor.RED;
				}
			case 3, 6, 12:
				if (val % 3 == 0)
					return FlxColor.RED;
				else if (val == 0)
					return FlxColor.WHITE;
				else
					return FlxColor.PURPLE;
			case 8, 16:
				if (val == 0)
					return FlxColor.WHITE;
				else if ((i - 1) % 2 == 0)
					return FlxColor.fromRGB(255, 215, 0);
				else if (i % 4 == 0)
					return FlxColor.RED;
				else
					return 0xFF0085ff;
			default:
				if (val == 0)
					return FlxColor.WHITE;

				return (i % 2 == 0) ? 0xFFaf4fb8 : 0xFF4e94b7;
		}
	}
}