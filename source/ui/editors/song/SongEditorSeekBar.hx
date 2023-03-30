package ui.editors.song;

import data.song.DifficultyProcessor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;
import states.editors.SongEditorState;
import util.editors.actions.song.SongEditorActionManager;

class SongEditorSeekBar extends FlxSpriteGroup
{
	public var bg:FlxSprite;

	var state:SongEditorState;
	var rectWidth = 38;
	var rectHeight = FlxG.height;
	var maxBars:Int = 200;
	var barSize:Int = 2;
	var barWidthScale:Float = 0.85;
	var barsSprite:FlxSprite;
	var seekLine:FlxSprite;
	var isHeld:Bool = false;
	var scheduledFunction:Void->Void;

	public function new(state:SongEditorState)
	{
		super(state.playfieldNotes.bg.x, 0);
		this.state = state;

		bg = new FlxSprite().makeGraphic(rectWidth, rectHeight, 0xFF181818);
		add(bg);

		var borderLeft = new FlxSprite().makeGraphic(2, rectHeight, 0xFF808080);
		add(borderLeft);

		var borderRight = new FlxSprite(bg.width - 2).makeGraphic(2, rectHeight, 0xFF808080);
		add(borderRight);

		barsSprite = new FlxSprite().makeGraphic(rectWidth, rectHeight, FlxColor.TRANSPARENT, true, 'seekBars');
		add(barsSprite);

		createBars();

		seekLine = new FlxSprite(0, (state.inst.time / state.inst.length) * bg.height).makeGraphic(Std.int(bg.width), 4);
		add(seekLine);

		scrollFactor.set();

		x -= bg.width + 80;

		state.actionManager.onEvent.add(onEvent);
	}

	override function update(elapsed:Float)
	{
		if (scheduledFunction != null)
		{
			scheduledFunction();
			scheduledFunction = null;
		}

		if (!isHeld && FlxG.mouse.overlaps(bg) && FlxG.mouse.justPressed)
			isHeld = true;
		if (FlxG.mouse.released)
			isHeld = false;

		if (isHeld && FlxG.mouse.pressed)
		{
			var percentage = (FlxG.mouse.globalY - bg.y) / bg.height;
			seekToPos((1 - percentage) * state.inst.length);
		}

		if (seekLine != null)
			seekLine.y = FlxMath.remapToRange(state.inst.time, 0, state.inst.length, bg.y + bg.height - seekLine.height, bg.y);
	}

	function createBars()
	{
		if (state.song.notes.length == 0)
			return clearBarsSprite();

		var sampleTime = Math.ceil(state.inst.length / maxBars);
		var regularLength = state.inst.length;
		var diffLeft = state.song.solveDifficulty(false);
		var diffRight = state.song.solveDifficulty(true);
		var diffs = [diffLeft, diffRight];

		var bins:Map<String, Array<StrainSolverData>> = new Map();
		var time = 0;
		while (time < regularLength)
		{
			var valuesInBin:Array<StrainSolverData> = [];
			for (diff in diffs)
			{
				for (bin in diff.strainSolverData)
				{
					if (bin.startTime >= time && bin.startTime < time + sampleTime)
						valuesInBin.push(bin);
				}
			}
			var pos = time / regularLength;
			bins.set(Std.string(pos), valuesInBin);
			time += sampleTime;
		}

		if (time == 0)
			return;

		var highestDiff:Float = 0;
		for (bin in bins)
		{
			if (bin.length > 0)
			{
				var diff:Float = 0;
				for (data in bin)
					diff += data.totalStrainValue;
				diff /= bin.length;

				if (diff > highestDiff)
					highestDiff = diff;
			}
		}

		scheduledFunction = function()
		{
			clearBarsSprite();
			barsSprite.pixels.lock();
			for (key => bin in bins)
			{
				var rating:Float = 0;
				for (data in bin)
					rating += data.totalStrainValue;
				rating /= bin.length;

				if (rating < 0.05)
					continue;

				var pos = Std.parseFloat(key);
				var width = FlxMath.bound(rating / highestDiff * bg.width, 4, bg.width);

				barsSprite.pixels.fillRect(new Rectangle(bg.width - width, rectHeight * (1 - pos) - 2 - barSize, width, barSize),
					DifficultyProcessor.getDifficultyColor(rating));
			}
			barsSprite.pixels.unlock();
		}
	}

	function clearBarsSprite()
	{
		barsSprite.pixels.lock();
		barsSprite.pixels.fillRect(new Rectangle(0, 0, barsSprite.pixels.width, barsSprite.pixels.height), FlxColor.TRANSPARENT);
		barsSprite.pixels.unlock();
	}

	function seekToPos(targetPos:Float)
	{
		if (Math.round(targetPos) != Math.round(state.inst.time) && targetPos >= 0 && targetPos <= state.inst.length)
		{
			if (Math.abs(state.inst.time - targetPos) < 500)
				return;

			state.setSongTime(targetPos);
		}
	}

	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_NOTE, SongEditorActionManager.REMOVE_NOTE, SongEditorActionManager.ADD_NOTE_BATCH,
				SongEditorActionManager.REMOVE_NOTE_BATCH, SongEditorActionManager.RESIZE_LONG_NOTE, SongEditorActionManager.FLIP_NOTES:
				createBars();
			case SongEditorActionManager.MOVE_OBJECTS, SongEditorActionManager.RESNAP_OBJECTS:
				if (params.notes != null && params.notes.length > 0)
					createBars();
		}
	}
}
