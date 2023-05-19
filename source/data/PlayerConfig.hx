package data;

import data.Controls;

typedef PlayerConfig =
{
	var device:PlayerConfigDevice;
	var controls:Map<Control, Array<Int>>;
	var ?scrollSpeed:Float;
	var downScroll:Bool;
	var ?judgementCounter:Bool;
	var ?npsDisplay:Bool;
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
