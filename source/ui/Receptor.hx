package ui;

import data.ReceptorSkin;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

/**
	A receptor is a static note sprite that indicates when you should hit a note.
	It gives feedback whenever you press it and also if you hit a note or not.
**/
class Receptor extends FlxSprite
{
	public var lane(default, null):Int;
	public var skin(default, null):ReceptorSkin;
	public var alphaTween(default, null):FlxTween;

	public function new(x:Float = 0, y:Float = 0, lane:Int = 0, ?skin:ReceptorSkin)
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

	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (!animation.exists(name))
			return false;

		animation.play(name, force, reversed, frame);

		if (skin.receptorsCenterAnimation == true)
		{
			centerOffsets();
		}

		return true;
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
