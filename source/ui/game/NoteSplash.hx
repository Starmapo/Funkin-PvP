package ui.game;

import data.PlayerConfig;
import data.skin.SplashSkin;
import flixel.FlxG;
import sprites.AnimatedSprite;

class NoteSplash extends AnimatedSprite
{
	public var defaultAlphaMult:Float = 0.6;
	public var alphaMult:Float = 0.00001;

	var id:Int;
	var skin:SplashSkin;
	var receptor:Receptor;
	var splashData:SplashData;
	var offsetScale:Float;

	public function new(id:Int, skin:SplashSkin, ?receptor:Receptor, ?config:PlayerConfig)
	{
		offsetScale = config != null ? config.notesScale : 1;
		super(0, 0, null, skin.scale * offsetScale);
		this.id = id;
		this.skin = skin;
		this.receptor = receptor;

		if (Paths.isSpritesheet(skin.image, skin.mod))
			frames = Paths.getSpritesheet(skin.image, skin.mod);
		else
			loadGraphic(Paths.getImage(skin.image, skin.mod), true, skin.tileWidth, skin.tileHeight);

		splashData = skin.splashes[id];
		addAnim({
			name: 'splash',
			atlasName: splashData.anim,
			indices: splashData.indices,
			fps: splashData.fps,
			loop: false,
			offset: splashData.offset
		}, true);
		frameOffsetScale = skin.scale;
		antialiasing = skin.antialiasing;
		scrollFactor.set();
	}

	public function startSplash()
	{
		stopAnimCallback();
		playAnim('splash', true);
		if (animation.curAnim != null)
			animation.curAnim.frameRate = splashData.fps + FlxG.random.int(-2, 2);

		alphaMult = defaultAlphaMult;
		updatePosition();
		animation.finishCallback = function(name)
		{
			stopAnimCallback();
			alphaMult = 0.00001;
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
			setPosition(receptor.x
				+ (receptor.staticWidth / 2)
				- (width / 2)
				+ skin.positionOffset[0] * offsetScale,
				receptor.y
				+ (receptor.staticHeight / 2)
				- (height / 2)
				+ skin.positionOffset[1] * offsetScale);
	}
}
