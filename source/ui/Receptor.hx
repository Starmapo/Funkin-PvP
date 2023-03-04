package ui;

import data.skin.NoteSkin;
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

			addAnim({
				name: 'static',
				atlasName: data.staticAnim,
				fps: data.staticFPS,
				offset: data.staticOffset
			});
			addAnim({
				name: 'pressed',
				atlasName: data.pressedAnim,
				fps: data.pressedFPS,
				loop: false,
				offset: data.pressedOffset
			});
			addAnim({
				name: 'confirm',
				atlasName: data.confirmAnim,
				fps: data.confirmFPS,
				loop: false,
				offset: data.confirmOffset
			});

			playAnim('static', true);
			scale.set(skin.receptorsScale, skin.receptorsScale);
			updateHitbox();

			antialiasing = skin.antialiasing;
		}
		scrollFactor.set();
	}

	override public function animPlayed(name:String)
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
}
