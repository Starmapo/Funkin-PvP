function onCreate()
{
	var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.getImage('stages/christmas/evilBG'));
	bg.antialiasing = true;
	bg.scrollFactor.set(0.2, 0.2);
	bg.active = false;
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	addBehindChars(bg);

	var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.getImage('stages/christmas/evilTree'));
	evilTree.antialiasing = true;
	evilTree.scrollFactor.set(0.2, 0.2);
	evilTree.active = false;
	addBehindChars(evilTree);

	var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.getImage("stages/christmas/evilSnow"));
	evilSnow.antialiasing = true;
	evilTree.active = false;
	addBehindChars(evilSnow);

	bf.charPosX += 320;

	close();
}
