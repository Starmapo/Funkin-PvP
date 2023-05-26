package ui.game;

import data.PlayerConfig;
import data.skin.NoteSkin;
import flixel.FlxG;
import sprites.AnimatedSprite;

class NoteSplash extends AnimatedSprite
{
	public var alphaMult:Float = 0.6;

	var id:Int;
	var noteSkin:NoteSkin;
	var receptor:Receptor;
	var splashData:SplashData;

	public function new(id:Int, noteSkin:NoteSkin, receptor:Receptor, config:PlayerConfig)
	{
		super(0, 0, Paths.getSpritesheet(noteSkin.splashesImage), noteSkin.splashesScale * config.notesScale);
		this.id = id;
		this.noteSkin = noteSkin;
		this.receptor = receptor;

		splashData = noteSkin.splashes[id];
		if (splashData != null)
		{
			addAnim({
				name: 'splash',
				atlasName: splashData.anim,
				fps: splashData.fps,
				loop: false,
				offset: splashData.offset
			}, true);
		}
		offsetScale.scale(config.notesScale);
		kill();
	}

	public function startSplash()
	{
		animation.finishCallback = null;

		playAnim('splash', true);
		if (animation.curAnim != null && splashData != null)
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
		alpha = receptor.alpha * alphaMult;
	}

	override function destroy()
	{
		super.destroy();
		noteSkin = null;
		receptor = null;
		splashData = null;
	}

	public function updatePosition()
	{
		setPosition(receptor.x + (receptor.width / 2) - (width / 2), receptor.y + (receptor.height / 2) - (height / 2));
	}
}
