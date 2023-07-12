package ui.game;

import data.PlayerConfig;
import data.PlayerSettings;
import data.Settings;
import data.char.CharacterInfo;
import data.game.GameplayGlobals;
import data.game.ScoreProcessor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

using StringTools;

class HealthBar extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var bar:FlxBar;
	public var icon:HealthIcon;
	public var bopScale:Float = 1.2;

	var scoreProcessor:ScoreProcessor;
	var right:Bool;

	public function new(?scoreProcessor:ScoreProcessor, charInfo:CharacterInfo)
	{
		super();
		this.scoreProcessor = scoreProcessor;
		var player = scoreProcessor != null ? scoreProcessor.player : 0;
		var config = scoreProcessor != null ? Settings.playerConfigs[player] : null;

		var barWidth = Std.int((FlxG.width / 2) - 200);
		var barHeight = 20;

		right = (player > 0);
		setPosition((FlxG.width / 2 - barWidth) / 2 + (right ? FlxG.width / 2 : 0),
			(config != null && config.downScroll ? 100 - barHeight : FlxG.height - 100));

		bg = new FlxSprite().makeGraphic(barWidth, barHeight, FlxColor.BLACK);
		add(bg);

		bar = new FlxBar(4, 4, right ? RIGHT_TO_LEFT : LEFT_TO_RIGHT, Std.int(bg.width) - 8, Std.int(bg.height) - 8, scoreProcessor, 'health');
		bar.numDivisions = Std.int(bar.width);
		add(bar);

		icon = new HealthIcon(0, 0);
		icon.flipX = right;
		add(icon);

		if (scoreProcessor != null)
			alpha = Settings.healthBarAlpha;
		scrollFactor.set();

		setCharInfo(charInfo);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var scale = FlxMath.lerp(1, icon.scale.x, 1 - (elapsed * 9 * GameplayGlobals.playbackRate));
		icon.scale.set(scale, scale);
		icon.updateOffset();

		var anim = 'normal';
		if (bar.percent > 80)
			anim = 'winning';
		else if (bar.percent < 20)
			anim = 'losing';
		if (icon.animation.name != anim && icon.animation.exists(anim))
			icon.playAnim(anim);

		updateIconPos();
	}

	override function destroy()
	{
		super.destroy();
		bg = FlxDestroyUtil.destroy(bg);
		bar = FlxDestroyUtil.destroy(bar);
		icon = FlxDestroyUtil.destroy(icon);
		scoreProcessor = null;
	}

	public function onBeatHit()
	{
		icon.scale.set(bopScale, bopScale);
		icon.updateOffset();

		updateIconPos();
	}

	public function updateIconPos()
	{
		var percent = bar.percent / 100;
		var addX = (right ? bar.width - (bar.width * percent) : bar.width * percent);
		icon.setPosition(bar.x
			+ addX
			- (icon.width / 2)
			+ icon.info.positionOffset[0] * (right ? -1 : 1),
			bar.y
			+ (bar.height / 2)
			- (icon.height / 2)
			+ icon.info.positionOffset[1]);
	}

	public function setCharInfo(charInfo:CharacterInfo)
	{
		if (charInfo != null && (Settings.healthBarColors || scoreProcessor == null))
			bar.createFilledBar(charInfo.healthColors.getDarkened(0.5), charInfo.healthColors);
		else
			bar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		bar.updateBar();

		var iconName = charInfo != null ? charInfo.healthIcon : 'fnf:face';
		if (!iconName.contains(':'))
			iconName = charInfo.mod + ':' + iconName;
		icon.icon = iconName;
	}
}
