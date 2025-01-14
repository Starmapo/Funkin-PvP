package objects.game;

import backend.settings.PlayerConfig;
import backend.structures.skin.SplashSkin;
import flixel.FlxG;

class NoteSplash extends AnimatedSprite
{
	public var defaultAlphaMult:Float = 0.6;
	public var alphaMult:Float = 0.00001;
	
	var id:Int;
	var skin:SplashSkin;
	var receptor:Receptor;
	var splashData:SplashData;
	var configScale:Float;
	
	public function new(id:Int, skin:SplashSkin, ?receptor:Receptor, ?config:PlayerConfig)
	{
		configScale = config != null ? config.notesScale : 1;
		super(0, 0, null, (skin?.scale ?? 1.0) * configScale);
		this.id = id;
		this.skin = skin;
		this.receptor = receptor;
		
		scrollFactor.set();
		
		if (skin == null)
			return;
		if (Paths.isSpritesheet(skin.image, skin.mod))
			frames = Paths.getSpritesheet(skin.image, skin.mod);
		else
			loadGraphic(Paths.getImage(skin.image, skin.mod), true, skin.tileWidth, skin.tileHeight);
			
		splashData = skin.splashes[id];
		addAnim({
			name: 'splash',
			prefix: splashData.anim,
			indices: splashData.indices,
			fps: splashData.fps,
			loop: false,
			offset: splashData.offset
		}, true);
		setOffsetScale(skin.scale, skin.scale);
		antialiasing = skin.antialiasing && Settings.antialiasing;
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
		{
			final posOffset = skin?.positionOffset ?? [0.0, 0.0];
			setPosition(receptor.x
				+ (receptor.staticWidth / 2)
				- (width / 2)
				+ posOffset[0] * configScale,
				receptor.y
				+ (receptor.staticHeight / 2)
				- (height / 2)
				+ posOffset[1] * configScale);
		}
	}
}
