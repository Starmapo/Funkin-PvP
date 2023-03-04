package states.options;

import data.Controls.Control;
import data.PlayerConfig;
import data.Settings;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ControlsPage extends Page
{
	var player:Int = 0;

	public function new(player:Int)
	{
		super();
		this.player = player;
	}

	override function update(elapsed:Float)
	{
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;

		super.update(elapsed);
	}
}

class ControlItem extends FlxSpriteGroup
{
	var name:String;
	var control:Control;
	var label:FlxText;
	var button1:FlxUIButton;
	var button2:FlxUIButton;
	var playerConfig:PlayerConfig;

	public function new(name:String, control:Control, player:Int)
	{
		super();
		this.name = name;
		this.control = control;
		playerConfig = Settings.playerConfigs[player];

		label = new FlxText(0, 0, 100, name);
		label.setFormat('Nokia Cellphone FC Small', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(label);

		button1 = createButton(0);
		button2 = createButton(1);
	}

	function createButton(id:Int)
	{
		var bind = playerConfig.controls.get(control)[id];
		var text:String = switch (playerConfig.device)
		{
			case Keyboard:
				(bind : FlxKey).toString();
			case Gamepad(_):
				(bind : FlxGamepadInputID).toString();
			case None:
				'';
		}
		var button = new FlxUIButton(label.width, 0, text);
		if (id > 0)
		{
			button.x += button1.width;
		}
		return button;
	}
}
