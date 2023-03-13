package states.editors.song;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class SongEditorState extends FNFState
{
	public var columnSize:Int = 74;
	public var hitPositionY:Int = 820;

	var actionManager:SongEditorActionManager;
	var playfieldBG:FlxSprite;
	var borderLeft:FlxSprite;
	var borderRight:FlxSprite;
	var dividerLines:FlxTypedGroup<FlxSprite>;
	var hitPositionLine:FlxSprite;

	override function create()
	{
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		add(bg);

		playfieldBG = new FlxSprite().makeGraphic(columnSize * 4, FlxG.height, FlxColor.fromRGB(24, 24, 24));
		playfieldBG.screenCenter(X);
		playfieldBG.scrollFactor.set();
		add(playfieldBG);

		borderLeft = new FlxSprite(playfieldBG.x).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderLeft.scrollFactor.set();
		add(borderLeft);

		borderRight = new FlxSprite(playfieldBG.x + playfieldBG.width).makeGraphic(2, Std.int(playfieldBG.height), 0xFF808080);
		borderRight.x -= borderRight.width;
		borderRight.scrollFactor.set();
		add(borderRight);

		dividerLines = new FlxTypedGroup();
		for (i in 0...3)
		{
			var dividerLine = new FlxSprite(playfieldBG.x + (columnSize * (i + 1))).makeGraphic(2, Std.int(playfieldBG.height), FlxColor.WHITE);
			dividerLine.alpha = 0.35;
			dividerLines.add(dividerLine);
		}
		add(dividerLines);

		hitPositionLine = new FlxSprite(0, hitPositionY).makeGraphic(Std.int(playfieldBG.width - borderLeft.width * 2), 6, FlxColor.fromRGB(9, 165, 200));
		hitPositionLine.screenCenter(X);
		add(hitPositionLine);

		actionManager = new SongEditorActionManager(this);

		super.create();
	}
}
