package data;

import Controls;

typedef PlayerConfig =
{
	var name:String;
	var device:PlayerConfigDevice;
	var controls:Map<Control, Array<Int>>;
}

enum PlayerConfigDevice
{
	Keyboard;
	Gamepad(name:String);
	None;
}
