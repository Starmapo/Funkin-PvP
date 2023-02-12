package data;

import data.Controls;

typedef PlayerConfig =
{
	var device:PlayerConfigDevice;
	var controls:Map<Control, Array<Int>>;
}

enum PlayerConfigDevice
{
	Keyboard;
	Gamepad(name:String);
	None;
}
