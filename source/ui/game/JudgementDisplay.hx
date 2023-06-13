package ui.game;

import data.game.Judgement;
import data.skin.JudgementSkin;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;

class JudgementDisplay extends FlxSprite
{
	public static function getJudgementGraphic(judgement:Judgement, skin:JudgementSkin)
	{
		var name = Judgement.getJudgementName(judgement).toLowerCase();
		var mod = skin.mod;
		var path = 'judgements/${skin.name}/$name';
		if (!Paths.existsPath('images/$path.png', mod) && judgement == MARV)
		{
			name = Judgement.getJudgementName(SICK).toLowerCase();
			path = 'judgements/${skin.name}/$name';
		}
		/*
			if (!Paths.existsPath('images/$path.png', mod))
			{
				path = 'judgements/default/$name';
				mod = 'fnf';
			}
		 */
		return Paths.getImage(path, mod);
	}

	public var graphics:Array<FlxGraphic> = [];

	var player:Int;
	var skin:JudgementSkin;
	var posTween:FlxTween;
	var alphaTween:FlxTween;

	public function new(player:Int, skin:JudgementSkin)
	{
		super();
		this.player = player;
		this.skin = skin;

		for (i in 0...6)
		{
			var graphic = getJudgementGraphic(i, skin);
			graphic.destroyOnNoUse = false;
			graphics.push(graphic);
		}

		scale.set(skin.scale, skin.scale);
		antialiasing = skin.antialiasing;
		kill();
	}

	public function showJudgement(judgement:Judgement)
	{
		if (judgement == GHOST)
			return;

		var daGraphic = graphics[judgement];
		if (daGraphic == null)
			return;

		revive();
		loadGraphic(daGraphic);
		updateHitbox();

		if (posTween != null)
			posTween.cancel();
		if (alphaTween != null)
			alphaTween.cancel();

		x = (((FlxG.width / 2) - width) / 2) + (FlxG.width / 2) * player;
		y = (FlxG.height * 0.5) - (height / 2) + 20;

		posTween = FlxTween.tween(this, {y: y + 5}, 0.2);

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
		skin = null;
		if (posTween != null)
			posTween.cancel();
		posTween = null;
		if (alphaTween != null)
			alphaTween.cancel();
		alphaTween = null;
		if (graphics != null)
		{
			for (graphic in graphics)
			{
				if (graphic != null)
					graphic.destroyOnNoUse = false;
			}
		}
		graphics = null;
	}
}
