function onCreate()
{
	state.defaultCamZoom = 0.9;
	
	var bg = new BGSprite('stages/stage/stageback', -600, -200, 0.9, 0.9);
	addBehindChars(bg);
	
	var stageFront = new BGSprite('stages/stage/stagefront', -650, 600, 0.9, 0.9);
	stageFront.scale.set(1.1, 1.1);
	stageFront.updateHitbox();
	addBehindChars(stageFront);

	var stageCurtains = new BGSprite('stages/stage/stagecurtains', -500, -300, 1.3, 1.3);
	stageCurtains.scale.set(0.9, 0.9);
	stageCurtains.updateHitbox();
	addBehindChars(stageCurtains);
				
	close();
}