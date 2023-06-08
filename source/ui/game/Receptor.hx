package ui.game;

import data.PlayerConfig;
import data.skin.NoteSkin;
import sprites.AnimatedSprite;

class Receptor extends AnimatedSprite
{
	public var lane(default, null):Int;
	public var skin(default, null):NoteSkin;
	public var staticWidth:Float;
	public var staticHeight:Float;
	public var targetAlpha:Float = 1;

	public function new(x:Float = 0, y:Float = 0, lane:Int = 0, ?skin:NoteSkin, ?config:PlayerConfig)
	{
		super(x, y);
		this.lane = lane;
		this.skin = skin;

		if (skin != null && skin.receptors[lane] != null)
		{
			var data = skin.receptors[lane];

			if (Paths.isSpritesheet(skin.image, skin.mod))
				frames = Paths.getSpritesheet(skin.image, skin.mod);
			else
				loadGraphic(Paths.getImage(skin.image, skin.mod), true, skin.tileWidth, skin.tileHeight);

			var configScale = config != null ? config.notesScale : 1;
			var noteScale = skin.receptorsScale * configScale;
			scale.scale(noteScale);
			offsetScale.scale(configScale);

			addAnim({
				name: 'static',
				atlasName: data.staticAnim,
				indices: data.staticIndices,
				fps: data.staticFPS,
				offset: data.staticOffset
			}, true);
			staticWidth = width;
			staticHeight = height;

			addAnim({
				name: 'pressed',
				atlasName: data.pressedAnim,
				indices: data.pressedIndices,
				fps: data.pressedFPS,
				loop: false,
				offset: data.pressedOffset
			});

			addAnim({
				name: 'confirm',
				atlasName: data.confirmAnim,
				indices: data.confirmIndices,
				fps: data.confirmFPS,
				loop: false,
				offset: data.confirmOffset
			});

			antialiasing = skin.antialiasing;
		}
		scrollFactor.set();

		targetAlpha = config != null && config.transparentReceptors ? 0.8 : 1;
		alpha = targetAlpha;

		playAnim('static', true);
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
