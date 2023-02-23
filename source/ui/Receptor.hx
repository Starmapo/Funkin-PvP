package ui;

import data.skin.NoteSkin;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import sprites.AnimatedSprite;

/**
	A receptor is a static note sprite that indicates when you should hit a note.
	It gives feedback whenever you press it and also if you hit a note or not.
**/
class Receptor extends AnimatedSprite
{
	public var lane(default, null):Int;
	public var skin(default, null):NoteSkin;
	public var alphaTween(default, null):FlxTween;

	public function new(x:Float = 0, y:Float = 0, lane:Int = 0, ?skin:NoteSkin)
	{
		super(x, y);
		this.lane = lane;
		this.skin = skin;

		if (skin != null && skin.receptors[lane] != null)
		{
			var data = skin.receptors[lane];

			frames = Paths.getSpritesheet(skin.receptorsImage);

			addAnim('static', data.staticAnim, data.staticFPS, true, data.staticOffset);
			addAnim('pressed', data.pressedAnim, data.pressedFPS, false, data.pressedOffset);
			addAnim('confirm', data.confirmAnim, data.confirmFPS, false, data.confirmOffset);

			playAnim('static', true);
			scale.set(skin.receptorsScale, skin.receptorsScale);
			updateHitbox();

			antialiasing = skin.antialiasing;
		}
		scrollFactor.set();
	}

	override public function animPlayed(animName:String)
	{
		if (skin.receptorsCenterAnimation)
		{
			centerOffsets();
		}
	}

	public function startAlphaTween(alpha:Float, duration:Float = 1, ?options:TweenOptions)
	{
		if (alphaTween != null)
			alphaTween.cancel();

		alphaTween = FlxTween.tween(this, {alpha: alpha}, duration, options);
	}

	function addAnim(name:String, atlasName:String, ?fps:Float, loop:Bool = true, ?offsets:Array<Float>)
	{
		animation.addByAtlasName(name, atlasName, fps, loop);
		animation.addOffset(name, offsets[0], offsets[1]);
	}
}
