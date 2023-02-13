package data;

import data.Controls;

typedef PlayerConfig =
{
	var device:PlayerConfigDevice;
	var controls:Map<Control, Array<Int>>;
	var downScroll:Bool;
}

enum PlayerConfigDevice
{
	Keyboard;
	Gamepad(name:String);
	None;
}
