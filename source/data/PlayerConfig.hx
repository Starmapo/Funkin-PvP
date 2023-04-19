package data;

import data.Controls;

typedef PlayerConfig =
{
	var device:PlayerConfigDevice;
	var controls:Map<Control, Array<Int>>;
	var ?scrollSpeed:Float;
	var downScroll:Bool;
}

enum PlayerConfigDevice
{
	KEYBOARD;
	GAMEPAD(id:Int);
	NONE;
}
