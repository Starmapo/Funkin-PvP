package ui.editors.song;

import data.Settings;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import states.editors.SongEditorState;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorTimeline extends FlxBasic
{
	public var lines:Array<SongEditorTimelineTick>;

	var state:SongEditorState;
	var cachedLines:Map<Int, Array<SongEditorTimelineTick>> = new Map();

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		initializeLines();

		state.rateChanged.add(onRateChanged);
		state.beatSnap.valueChanged.add(onBeatSnapChanged);
		state.actionManager.onEvent.add(onEvent);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function draw()
	{
		for (i in 0...lines.length)
		{
			var line = lines[i];
			if (line.isOnScreen())
				line.draw();
		}
	}

	override function destroy()
	{
		for (lines in cachedLines)
		{
			for (line in lines)
				FlxDestroyUtil.destroy(line);
		}
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
		super.destroy();
	}

	public function initializeLines()
	{
		if (cachedLines.exists(state.beatSnap.value))
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

			if (point == state.song.timingPoints[0])
			{
				while (true)
				{
					if ((numBeatsOffsetted / state.beatSnap.value) % point.meter == 0
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

			var i = 0;
			while (i < pointLength / point.beatLength * state.beatSnap.value)
			{
				var time = startTime + point.beatLength / state.beatSnap.value * i;
				var measureBeat = (i / state.beatSnap.value) % point.meter == 0 && i % state.beatSnap.value == 0;

				var line = new SongEditorTimelineTick(state, point, time, i, measureCount, measureBeat);
				newLines.push(line);

				if (measureBeat && time >= point.startTime)
					measureCount++;

				i++;
			}
		}

		cachedLines.set(state.beatSnap.value, newLines);
		lines = newLines;
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshLines();
	}

	function onBeatSnapChanged(_, _)
	{
		initializeAndRefreshLines();
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_TIMING_POINT, SongEditorActionManager.REMOVE_TIMING_POINT:
				reinitialize();
		}
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

	function reinitialize()
	{
		for (lines in cachedLines)
		{
			for (line in lines)
				line.destroy();
		}

		lines.resize(0);
		cachedLines.clear();

		initializeLines();
	}

	function refreshLines()
	{
		for (line in lines)
			line.updatePosition();
	}

	function initializeAndRefreshLines()
	{
		initializeLines();
		refreshLines();
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
	var extendedHeight:Bool;

	public function new(state:SongEditorState, timingPoint:TimingPoint, time:Float, index:Int, measureCount:Int, isMeasureLine:Bool)
	{
		super();
		this.state = state;
		this.timingPoint = timingPoint;
		this.time = time;
		this.index = index;
		this.measureCount = measureCount;
		this.isMeasureLine = isMeasureLine;

		extendedHeight = isMeasureLine && time >= timingPoint.startTime;

		line = new FlxSprite().makeGraphic(Std.int(state.playfieldBG.width - 4), extendedHeight ? 5 : 2);
		updateColor();
		add(line);

		if (extendedHeight)
		{
			measureText = new FlxText(0, 0, 0, Std.string(measureCount));
			measureText.setFormat('VCR OSD Mono', 24);
			measureText.x = -measureText.width - 16;
			measureText.y -= measureText.height / 2;
			add(measureText);
		}

		updatePosition();
	}

	public function updatePosition()
	{
		x = state.playfieldBG.x + 2;
		y = state.hitPositionY - time * state.trackSpeed - line.height;
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
				if (val == 0)
					return FlxColor.WHITE;
				else if (val % 3 == 0)
					return FlxColor.RED;
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
