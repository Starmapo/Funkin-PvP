function onCreatePost()
{
	var blackBGThing = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	blackBGThing.screenCenter();
	blackBGThing.scrollFactor.set();
	insert(members.indexOf(lilStage), blackBGThing);
	
	state.disableCamFollow = true;
	camFollow.setPosition(155, 600);
	FlxG.camera.snapToTarget();
}