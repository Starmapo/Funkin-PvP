package sprites.game;

class BGSprite extends AnimatedSprite
{
	public var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, parX:Float = 1, parY:Float = 1, ?daAnimations:Array<String>, ?loopingAnim:Bool = false)
	{
		super(x, y);

		if (daAnimations != null)
		{
			frames = Paths.getSpritesheet(image);
			for (anims in daAnimations)
			{
				animation.addByPrefix(anims, anims, 24, loopingAnim);

				if (idleAnim == null)
				{
					idleAnim = anims;
					animation.play(anims);
				}
			}
		}
		else
		{
			loadGraphic(Paths.getImage(image));
			active = false;
		}

		scrollFactor.set(parX, parY);
		antialiasing = true;
	}

	public function dance():Void
	{
		if (idleAnim != null)
			animation.play(idleAnim);
	}
}
