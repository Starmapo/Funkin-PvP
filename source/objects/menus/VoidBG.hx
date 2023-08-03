package objects.menus;

import flixel.FlxSprite;

class VoidBG extends FlxSprite
{
	static var lastAngle:Float = 0;
	
	public function new()
	{
		super();
		var image = Paths.getImage('menus/pvp/voidBG');
		loadGraphic(image, true, image.width, Std.int(image.height / 3));
		animation.add('idle', [0, 1, 2], 4);
		animation.play('idle');
		
		setGraphicSize(1560);
		updateHitbox();
		screenCenter(X);
		
		alpha = 0.5;
		angle = lastAngle;
		angularVelocity = 5;
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		lastAngle = angle;
	}
}
