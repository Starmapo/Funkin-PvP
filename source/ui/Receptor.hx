package ui;

import data.ReceptorSkin;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

/**
	A receptor is a static arrow that indicates when you should hit a note.
	It also gives feedback whenever you press it and if you hit a note or not.
**/
class Receptor extends FlxSprite
{
	public var id(default, null):Int;
	public var skin(default, null):ReceptorSkin;
	public var alphaTween(default, null):FlxTween;

	public function new(x:Float = 0, y:Float = 0, id:Int = 0, ?skin:ReceptorSkin)
	{
		super(x, y);
		this.id = id;
		this.skin = skin;

		if (skin != null && skin.receptors[id] != null)
		{
			frames = Paths.getSpritesheet(skin.receptorsImage);

			addAnim('static', skin.receptors[id].staticAnim, skin.receptors[id].staticFPS, true, skin.receptors[id].staticOffset);
			addAnim('pressed', skin.receptors[id].pressedAnim, skin.receptors[id].pressedFPS, false, skin.receptors[id].pressedOffset);
			addAnim('confirm', skin.receptors[id].confirmAnim, skin.receptors[id].confirmFPS, false, skin.receptors[id].confirmOffset);

			playAnim('static', true);
			scale.set(skin.receptorsScale, skin.receptorsScale);
			updateHitbox();

			antialiasing = skin.antialiasing;
		}
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
		if (fps == null)
			fps = 24;

		animation.addByAtlasName(name, atlasName, fps, loop);
		if (offsets != null)
		{
			animation.addOffset(name, offsets[0], offsets[1]);
		}
	}
}
