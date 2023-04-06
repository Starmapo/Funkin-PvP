package ui.editors.song;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import states.editors.SongEditorState;

class SongEditorPlayfield extends FlxGroup
{
	public var columns:Int;
	public var columnSize:Int = 40;
	public var type:PlayfieldType;
	public var bg:FlxSprite;
	public var borderLeft:FlxSprite;
	public var borderRight:FlxSprite;
	public var dividerLines:FlxTypedGroup<FlxSprite>;
	public var hitPositionLine:FlxSprite;
	public var timeline:SongEditorTimeline;
	public var waveform:SongEditorWaveform;
	public var noteGroup:SongEditorNoteGroup;
	public var camFocusGroup:SongEditorCamFocusGroup;
	public var playfieldButton:SongEditorPlayfieldButton;

	var bgColor:FlxColor = FlxColor.fromRGB(24, 24, 24);
	var borderColor:FlxColor = 0xFF808080;
	var hitPositionLineColor:FlxColor = FlxColor.fromRGB(9, 165, 200);
	var state:SongEditorState;

	public function new(state:SongEditorState, type:PlayfieldType, columns:Int)
	{
		super();
		this.state = state;
		this.type = type;
		this.columns = columns;

		createBG();
		createBorders();
		createDividerLines();
		createHitPositionLine();
		createTimeline();
		createWaveform();
		if (type == NOTES)
			createNoteGroup();
		else
			createCamFocusGroup();
		createPlayfieldButton();
	}

	override function update(elapsed:Float)
	{
		playfieldButton.update(elapsed);
		timeline.update(elapsed);
		if (type == NOTES)
			noteGroup.update(elapsed);
	}

	public function getLaneFromX(x:Float)
	{
		var percentage = (x - bg.x) / bg.width;
		return FlxMath.boundInt(Std.int(columns * percentage), 0, columns);
	}

	public function getHoveredObject():ISongEditorTimingObject
	{
		if (!exists || FlxG.mouse.overlaps(state.playfieldTabs))
			return null;

		if (type == NOTES)
		{
			var obj = noteGroup.getHoveredNote();
			if (obj != null)
				return obj;
		}
		else
		{
			var obj = camFocusGroup.getHoveredCamFocus();
			if (obj != null)
				return obj;
		}

		return null;
	}

	public function isHoveringObject()
	{
		return getHoveredObject() != null;
	}

	function createBG()
	{
		bg = new FlxSprite().makeGraphic(columnSize * columns, FlxG.height, bgColor);
		bg.screenCenter(X);
		bg.scrollFactor.set();
		add(bg);
	}

	function createBorders()
	{
		borderLeft = new FlxSprite(bg.x).makeGraphic(2, Std.int(bg.height), borderColor);
		borderLeft.scrollFactor.set();
		add(borderLeft);

		borderRight = new FlxSprite(bg.x + bg.width).makeGraphic(2, Std.int(bg.height), borderColor);
		borderRight.x -= borderRight.width;
		borderRight.scrollFactor.set();
		add(borderRight);
	}

	function createDividerLines()
	{
		dividerLines = new FlxTypedGroup();
		for (i in 1...columns)
		{
			var thickDivider = i == 4 && type == NOTES;
			var dividerLine = new FlxSprite(bg.x + (columnSize * i)).makeGraphic(2, Std.int(bg.height), borderColor);
			if (!thickDivider)
				dividerLine.alpha = 0.35;
			dividerLine.scrollFactor.set();
			dividerLines.add(dividerLine);
		}
		add(dividerLines);
	}

	function createHitPositionLine()
	{
		hitPositionLine = new FlxSprite(0, state.hitPositionY).makeGraphic(Std.int(bg.width - borderLeft.width * 2), 6, hitPositionLineColor);
		hitPositionLine.screenCenter(X);
		hitPositionLine.scrollFactor.set();
		add(hitPositionLine);
	}

	function createTimeline()
	{
		timeline = new SongEditorTimeline(state, this);
		add(timeline);
	}

	function createWaveform()
	{
		waveform = new SongEditorWaveform(state, this);
		add(waveform);
	}

	function createNoteGroup()
	{
		noteGroup = new SongEditorNoteGroup(state, this);
		add(noteGroup);
	}

	function createCamFocusGroup()
	{
		camFocusGroup = new SongEditorCamFocusGroup(state, this);
		add(camFocusGroup);
	}

	function createPlayfieldButton()
	{
		playfieldButton = new SongEditorPlayfieldButton(0, state.playfieldTabs.height, state, this);
		playfieldButton.screenCenter(X);
	}
}

enum PlayfieldType
{
	NOTES;
	OTHER;
}
