package ui.game;

import data.PlayerConfig;
import data.skin.SplashSkin;
import flixel.FlxG;
import sprites.AnimatedSprite;

class NoteSplash extends AnimatedSprite
{
	public var alphaMult:Float = 0.6;

	var id:Int;
	var skin:SplashSkin;
	var receptor:Receptor;
	var splashData:SplashData;

	public function new(id:Int, skin:SplashSkin, ?receptor:Receptor, ?config:PlayerConfig)
	{
		var configScale = config != null ? config.notesScale : 1;
		super(0, 0, Paths.getSpritesheet(skin.image, skin.mod), skin.scale * configScale);
		this.id = id;
		this.skin = skin;
		this.receptor = receptor;

		splashData = skin.splashes[id];
		addAnim({
			name: 'splash',
			atlasName: splashData.anim,
			fps: splashData.fps,
			loop: false,
			offset: splashData.offset
		}, true);
		offsetScale.scale(configScale);
		antialiasing = skin.antialiasing;
		scrollFactor.set();

		kill();
	}

	public function startSplash()
	{
		animation.finishCallback = null;

		playAnim('splash', true);
		if (animation.curAnim != null)
			animation.curAnim.frameRate = splashData.fps + FlxG.random.int(-2, 2);

		revive();
		updatePosition();
		animation.finishCallback = function(name)
		{
			animation.finishCallback = null;
			kill();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updatePosition();
		if (receptor != null)
			alpha = receptor.alpha * alphaMult;
		else
			alpha = alphaMult;
	}

	override function destroy()
	{
		super.destroy();
		skin = null;
		receptor = null;
		splashData = null;
	}

	public function updatePosition()
	{
		if (receptor != null)
			setPosition(receptor.x + (receptor.staticWidth / 2) - (width / 2), receptor.y + (receptor.staticHeight / 2) - (height / 2));
	}
}
