package ui.game;

import data.Settings;
import data.game.Judgement;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class MSDisplay extends FlxText
{
	var player:Int;
	var posTween:FlxTween;
	var alphaTween:FlxTween;

	public function new(player:Int)
	{
		super();
		this.player = player;

		setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		kill();
	}

	public function showMS(ms:Float, judgement:Judgement)
	{
		revive();

		var t = FlxMath.roundDecimal(ms / Settings.playbackRate, 2) + 'ms';
		if (text != t)
			text = t;

		color = switch (judgement)
		{
			case GOOD:
				FlxColor.LIME;
			case BAD, SHIT:
				FlxColor.RED;
			default:
				FlxColor.CYAN;
		}

		x = (((FlxG.width / 2) - width) / 2) + (FlxG.width / 2) * player;
		y = (FlxG.height * 0.65) - (height / 2) - 20;

		if (posTween != null)
			posTween.cancel();
		posTween = FlxTween.tween(this, {y: y + 5}, 0.2);

		if (alphaTween != null)
			alphaTween.cancel();
		alpha = 1;
		alphaTween = FlxTween.tween(this, {alpha: 0}, 0.2, {
			onComplete: function(_)
			{
				kill();
			},
			startDelay: 0.2
		});
	}

	override function destroy()
	{
		super.destroy();
		if (posTween != null)
			posTween.cancel();
		posTween = null;
		if (alphaTween != null)
			alphaTween.cancel();
		alphaTween = null;
	}
}
