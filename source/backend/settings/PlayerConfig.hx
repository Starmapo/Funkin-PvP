package backend.settings;

typedef PlayerConfig =
{
	var device:PlayerConfigDevice;
	var controls:Map<Action, Array<Null<Int>>>;
	
	var ?scrollSpeed:Float;
	var ?downScroll:Bool;
	var ?noteSkin:String;
	var ?judgementSkin:String;
	var ?splashSkin:String;
	var ?notesScale:Float;
	var ?judgementCounter:Bool;
	var ?npsDisplay:Bool;
	var ?msDisplay:Bool;
	var ?transparentReceptors:Bool;
	var ?transparentHolds:Bool;
	var ?noteSplashes:Bool;
	var ?noReset:Bool;
	var ?autoplay:Bool;
}

enum PlayerConfigDevice
{
	KEYBOARD;
	GAMEPAD(id:Int);
	NONE;
}
