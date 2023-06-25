import("flixel.system.FlxBGSprite");

function onCreatePost()
{
	var blackBGThing = new FlxBGSprite();
	blackBGThing.color = FlxColor.BLACK;
	insert(members.indexOf(lilStage), blackBGThing);
	
	state.disableCamFollow = true;
	camFollow.setPosition(155, 600);
	FlxG.camera.snapToTarget();
}