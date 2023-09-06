var sprites:StringMap<String, FlxSprite> = new StringMap();
var tweens:StringMap<String, FlxTween> = new StringMap();
var platTiltDir = 4;
var yMove = 30;
var xMove = 35;

function onCreatePost()
{
	if (!Settings.lowQuality)
	{
		for (i in 1...8)
		{
			var image = "stages/AeroTornado/Debris" + (i == 5 ? 4 : i);
			var bgDebris = new FlxSprite(-1200, 900, Paths.getImage(image));
			bgDebris.scale.scale(0.82);
			bgDebris.updateHitbox();
			bgDebris.scrollFactor.scale(0.7);
			bgDebris.origin.set(bgDebris.width / 2, bgDebris.height / 2);
			insert(members.indexOf(plat), bgDebris);
			sprites.set("bgDebris" + i, bgDebris);
			
			var fgDebris = new FlxSprite(2000, 900, Paths.getImage(image));
			fgDebris.scale.scale(1.35);
			fgDebris.updateHitbox();
			fgDebris.scrollFactor.scale(1.2);
			fgDebris.origin.set(fgDebris.width / 2, fgDebris.height / 2);
			fgDebris.alpha = 0.88;
			add(fgDebris);
			sprites.set("fgDebris" + i, fgDebris);
			
			if (FlxG.random.bool(50))
				tweenFGDebris(i, true);
			else
				tweenBGDebris(i, true);
				
			if (i == 5)
				fgDebris.flipY = bgDebris.flipY = true;
		}
	}
	
	tweenPlat();
	tweenDadY();
	tweenDadX();
}

function tweenFGDebris(i, ?random = false)
{
	var name = "fgDebris" + i;
	if (tweens.exists(name + "x"))
		tweens.get(name + "x").cancel();
	if (tweens.exists(name + "rot"))
		tweens.get(name + "rot").cancel();
	
	var sprite = sprites.get(name);
	sprite.x = 2000;
	sprite.y = FlxG.random.int(-300, 1200);
	var fno = random ? FlxG.random.int(60, 110) : 78;
	var tweenTime = FlxG.random.int(130, 170) / fno;
	
	tweens.set(name + "x", FlxTween.tween(sprite, {x: -1800}, tweenTime, {onComplete: function(_) {
		tweenBGDebris(i);
	}}));
	tweens.set(name + "rot", FlxTween.tween(sprite, {angle: FlxG.random.int(-180, 180)}, tweenTime));
}

function tweenBGDebris(i, ?random = false)
{
	var name = "bgDebris" + i;
	if (tweens.exists(name + "x"))
		tweens.get(name + "x").cancel();
	if (tweens.exists(name + "rot"))
		tweens.get(name + "rot").cancel();
	
	var sprite = sprites.get(name);
	sprite.x = -1800;
	sprite.y = FlxG.random.int(-300, 1200);
	var fno = random ? FlxG.random.int(60, 110) : 78;
	var tweenTime = FlxG.random.int(160, 180) / fno;
	
	tweens.set(name + "x", FlxTween.tween(sprite, {x: 2000}, tweenTime, {onComplete: function(_) { tweenFGDebris(i); }}));
	tweens.set(name + "rot", FlxTween.tween(sprite, {angle: FlxG.random.int(-180, 180)}, tweenTime));
}

function tweenPlat()
{
	platTiltDir *= -1;
	FlxTween.angle(plat, plat.angle, platTiltDir, 1.6, {ease: FlxEase.sineInOut, onComplete: function(_) { tweenPlat(); }});
	FlxTween.tween(gf, {charPosY: 368 + (platTiltDir * 4)}, 1.6, {ease: FlxEase.sineInOut});
}

function tweenDadY()
{
	yMove *= -1;
	FlxTween.tween(opponent, {charPosY: 250 + yMove}, FlxG.random.int(145, 170) / 100, {ease: FlxEase.sineInOut, onComplete: function(_) { tweenDadY(); }});
}

function tweenDadX()
{
	xMove *= -1;
	FlxTween.tween(opponent, {charPosX: -200 + xMove}, FlxG.random.int(185, 225) / 100, {ease: FlxEase.sineInOut, onComplete: function(_) { tweenDadX(); }});
}