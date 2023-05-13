package ui.game;

import data.char.CharacterInfo;
import data.game.ScoreProcessor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

using StringTools;

class HealthBar extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var bar:FlxBar;
	public var icon:HealthIcon;

	var scoreProcessor:ScoreProcessor;
	var right:Bool;

	public function new(scoreProcessor:ScoreProcessor, charInfo:CharacterInfo)
	{
		super();
		this.scoreProcessor = scoreProcessor;

		var barWidth = Std.int((FlxG.width / 2) - 200);

		right = scoreProcessor.player > 0;
		setPosition((FlxG.width / 2 - barWidth) / 2 + (right ? FlxG.width / 2 : 0), 650);

		bg = new FlxSprite().makeGraphic(barWidth, 20, FlxColor.BLACK);
		add(bg);

		var healthColor = CoolUtil.getColorFromArray(charInfo.healthColors);
		bar = new FlxBar(4, 4, right ? RIGHT_TO_LEFT : LEFT_TO_RIGHT, Std.int(bg.width) - 8, Std.int(bg.height) - 8, scoreProcessor, 'health');
		bar.createFilledBar(healthColor.getDarkened(0.5), healthColor);
		bar.numDivisions = Std.int(bar.width);
		add(bar);

		var iconName = charInfo.healthIcon;
		if (!iconName.contains(':'))
			iconName = charInfo.mod + ':' + iconName;
		icon = new HealthIcon(0, 0, iconName);
		icon.flipX = right;
		add(icon);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var percent = bar.percent / 100;
		var addX = (right ? bar.width - (bar.width * percent) : bar.width * percent);
		icon.setPosition(bar.x + addX - (icon.width / 2), bar.y + (bar.height / 2) - (icon.height / 2));
	}

	override function destroy()
	{
		super.destroy();
		scoreProcessor = null;
	}
}
