package ui.game;

import data.game.Judgement;
import data.skin.NoteSkin;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class JudgementDisplay extends FlxSprite
{
	var player:Int;
	var noteSkin:NoteSkin;
	var posTween:FlxTween;
	var alphaTween:FlxTween;

	public function new(player:Int, noteSkin:NoteSkin)
	{
		super();
		this.player = player;
		this.noteSkin = noteSkin;

		for (i in 0...6)
			getJudgementGraphic(i);

		antialiasing = noteSkin.antialiasing;
		kill();
	}

	public function showJudgement(judgement:Judgement)
	{
		if (judgement == GHOST)
			return;

		revive();

		loadGraphic(getJudgementGraphic(judgement));
		scale.set(noteSkin.judgementsScale, noteSkin.judgementsScale);
		updateHitbox();

		x = (((FlxG.width / 2) - width) / 2) + (FlxG.width / 2) * player;
		screenCenter(Y);
		y -= 5;

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

	function getJudgementGraphic(judgement:Judgement)
	{
		var path = 'judgements/base/';
		path += switch (judgement)
		{
			case MARV:
				'marv';
			case SICK:
				'sick';
			case GOOD:
				'good';
			case BAD:
				'bad';
			case SHIT:
				'shit';
			default:
				'miss';
		}
		return Paths.getImage(path);
	}
}
