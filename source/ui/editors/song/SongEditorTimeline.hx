package ui.editors.song;

import data.Settings;
import data.song.ITimingObject;
import data.song.TimingPoint;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import states.editors.SongEditorState;
import util.editors.song.SongEditorActionManager;

class SongEditorTimeline extends FlxBasic
{
	public var lines:Array<SongEditorTimelineTick>;

	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var cachedLines:Map<Int, Array<SongEditorTimelineTick>> = new Map();
	var linePool:Array<SongEditorTimelineTick>;
	var lastPooledLineIndex:Int = -1;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield)
	{
		super();
		this.state = state;
		this.playfield = playfield;

		initializeLines();

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		state.beatSnap.valueChanged.add(onBeatSnapChanged);
		state.actionManager.onEvent.add(onEvent);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function update(elapsed:Float)
	{
		var i = linePool.length - 1;
		while (i >= 0)
		{
			var line = linePool[i];
			if (!line.objectOnScreen())
				linePool.remove(line);
			i--;
		}

		var i = lastPooledLineIndex + 1;
		while (i < lines.length)
		{
			var line = lines[i];
			if (line.objectOnScreen())
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
			refreshLines();
			initializeLinePool();
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

			if (state.song.timingPoints.length == 1)
				pointLength = state.inst.length - startTime;

			var i = 0;
			while (i < pointLength / point.beatLength * state.beatSnap.value)
			{
				var time = startTime + point.beatLength / state.beatSnap.value * i;
				var measureBeat = (i / state.beatSnap.value) % point.meter == 0 && i % state.beatSnap.value == 0;

				var line = new SongEditorTimelineTick(state, playfield, point, time, i, measureCount, measureBeat);
				newLines.push(line);

				if (measureBeat && time >= point.startTime)
					measureCount++;

				i++;
			}
		}

		cachedLines.set(state.beatSnap.value, newLines);
		lines = newLines;
		initializeLinePool();
	}

	function initializeLinePool()
	{
		linePool = [];
		lastPooledLineIndex = -1;

		for (i in 0...lines.length)
		{
			var line = lines[i];
			if (!line.objectOnScreen())
				continue;
			linePool.push(line);
			lastPooledLineIndex = i;
		}
	}

	function onSongSeeked(_, _)
	{
		initializeLinePool();
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshLines();
	}

	function onBeatSnapChanged(_, _)
	{
		initializeLines();
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_OBJECT, SongEditorActionManager.REMOVE_OBJECT:
				if (Std.isOfType(params.object, TimingPoint))
					reinitialize();
			case SongEditorActionManager.ADD_OBJECT_BATCH, SongEditorActionManager.REMOVE_OBJECT_BATCH, SongEditorActionManager.MOVE_OBJECTS,
				SongEditorActionManager.RESNAP_OBJECTS:
				var hasTP = false;
				var batch:Array<ITimingObject> = params.objects;
				for (obj in batch)
				{
					if (Std.isOfType(obj, TimingPoint))
					{
						hasTP = true;
						break;
					}
				}
				if (hasTP)
					reinitialize();
			case SongEditorActionManager.CHANGE_TIMING_POINT_BPM, SongEditorActionManager.CHANGE_TIMING_POINT_METER,
				SongEditorActionManager.CHANGE_TIMING_POINT_TIME:
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
		initializeLinePool();
	}
}

class SongEditorTimelineTick extends FlxSpriteGroup
{
	var state:SongEditorState;
	var playfield:SongEditorPlayfield;
	var timingPoint:TimingPoint;
	var time:Float;
	var index:Int;
	var measureCount:Int;
	var isMeasureLine:Bool;
	var line:FlxSprite;
	var measureText:FlxText;
	var extendedHeight:Bool;

	public function new(state:SongEditorState, playfield:SongEditorPlayfield, timingPoint:TimingPoint, time:Float, index:Int, measureCount:Int,
			isMeasureLine:Bool)
	{
		super();
		this.state = state;
		this.playfield = playfield;
		this.timingPoint = timingPoint;
		this.time = time;
		this.index = index;
		this.measureCount = measureCount;
		this.isMeasureLine = isMeasureLine;

		extendedHeight = isMeasureLine && time >= timingPoint.startTime;

		line = new FlxSprite().makeGraphic(Std.int(playfield.bg.width - 4), extendedHeight ? 5 : 2);
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
		x = playfield.bg.x + 2;
		y = state.hitPositionY - time * state.trackSpeed - line.height;
	}

	public function updateColor()
	{
		line.color = getLineColor(index % state.beatSnap.value, index);
	}

	public function objectOnScreen()
	{
		return time * state.trackSpeed >= state.trackPositionY - playfield.bg.height
			&& time * state.trackSpeed <= state.trackPositionY + playfield.bg.height;
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
