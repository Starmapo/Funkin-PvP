package ui.game;

import data.PlayerConfig;
import data.skin.NoteSkin;
import flixel.tweens.FlxTween;
import sprites.AnimatedSprite;

class Receptor extends AnimatedSprite
{
	public var lane(default, null):Int;
	public var skin(default, null):NoteSkin;
	public var staticWidth:Float;
	public var staticHeight:Float;
	public var targetAlpha:Float = 1;

	public function new(x:Float = 0, y:Float = 0, lane:Int = 0, ?skin:NoteSkin, config:PlayerConfig)
	{
		super(x, y);
		this.lane = lane;
		this.skin = skin;

		if (skin != null && skin.receptors[lane] != null)
		{
			var data = skin.receptors[lane];

			frames = Paths.getSpritesheet(skin.receptorsImage);
			scale.set(skin.receptorsScale, skin.receptorsScale);

			addAnim({
				name: 'static',
				atlasName: data.staticAnim,
				fps: data.staticFPS,
				offset: data.staticOffset
			}, true);
			updateHitbox();
			staticWidth = width;
			staticHeight = height;

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

			antialiasing = skin.antialiasing;
		}
		scrollFactor.set();

		targetAlpha = config.transparentReceptors ? 0.8 : 1;
		alpha = targetAlpha;
	}

	override function destroy()
	{
		super.destroy();
		skin = null;
	}

	override public function animPlayed(name:String)
	{
		if (skin.receptorsCenterAnimation)
			offset.add((width - staticWidth) * 0.5, (height - staticHeight) * 0.5);
		
		if (name == 'confirm')
			alpha = 1;
		else
			alpha = targetAlpha;
	}
}
