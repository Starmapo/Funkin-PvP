function onCreate()
{
	var posX = 400;
	var posY = 200;

	var bg:FlxSprite = new FlxSprite(posX, posY);
	bg.frames = Paths.getSpritesheet('stages/weeb/animatedEvilSchool');
	bg.animation.addByPrefix('idle', 'background 2', 24);
	bg.animation.play('idle');
	bg.scrollFactor.set(0.8, 0.9);
	bg.scale.set(6, 6);
	addBehindChars(bg);

	var evilTrail = new FlxTrail(opponent, null, 4, 24, 0.3, 0.069);
	addBehindOpponent(evilTrail);

	bf.charPosX += 180;

	close();
}
