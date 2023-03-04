package states.options;

import data.Controls.Control;
import data.PlayerConfig;
import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ControlsPage extends Page
{
	var player:Int = 0;
	var items:FlxTypedGroup<ControlItem>;
	var pressBG:FlxSprite;
	var pressText:FlxText;
	var pressTime:Float = 0;
	var curItem:ControlItem;
	var curID:Int = 0;
	var playerSettings:PlayerSettings;
	var deviceText:FlxText;
	var deviceButton:FlxUIButton;
	var changingDevice:Bool = false;

	public function new(player:Int)
	{
		super();
		this.player = player;
		playerSettings = PlayerSettings.players[player];

		items = new FlxTypedGroup();
		add(items);

		deviceText = new FlxText(5, 0, FlxG.width - 10, '', 16);
		updateDeviceText();
		add(deviceText);

		deviceButton = new FlxUIButton(0, deviceText.y + deviceText.height + 5, 'Change Device', changeDevice);
		deviceButton.screenCenter(X);
		add(deviceButton);

		pressBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		pressBG.alpha = 0.8;
		pressBG.scrollFactor.set();
		pressBG.visible = false;
		add(pressBG);

		pressText = new FlxText(0, 0, FlxG.width - 10);
		pressText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		pressText.scrollFactor.set();
		pressText.visible = false;
		add(pressText);

		createItem('Left Note', NOTE_LEFT);
		createItem('Down Note', NOTE_DOWN);
		createItem('Up Note', NOTE_UP);
		createItem('Right Note', NOTE_RIGHT);
		createItem('UI Left', UI_LEFT);
		createItem('UI Down', UI_DOWN);
		createItem('UI Up', UI_UP);
		createItem('UI Right', UI_RIGHT);
		createItem('Accept', ACCEPT);
		createItem('Back', BACK);
		createItem('Pause', PAUSE);
		createItem('Reset', RESET);
	}

	override function update(elapsed:Float)
	{
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;

		if (pressTime > 0)
		{
			pressTime -= elapsed;
			if (pressTime <= 0)
			{
				hidePressText();
			}
			else
			{
				updatePressText();
				if (changingDevice)
				{
					var id = FlxG.keys.firstJustPressed();
					if (id > -1)
					{
						playerSettings.config.device = KEYBOARD;
						updateDeviceText();
						hidePressText();
					}

					var gamepad = FlxG.gamepads.getFirstActiveGamepad();
					if (gamepad != null)
					{
						playerSettings.config.device = GAMEPAD(gamepad.name);
						updateDeviceText();
						hidePressText();
					}
				}
				else
				{
					var id = playerSettings.controls.firstJustPressed();
					if (id > -1)
					{
						var binds = playerSettings.config.controls.get(curItem.control);

						binds[curID] = id;
						if (binds[1 - curID] == id)
							binds[1 - curID] = -1;

						curItem.updateLabels();
						hidePressText();
					}
				}
			}
		}

		if (controlsEnabled)
		{
			super.update(elapsed);
		}
	}

	override function onAppear()
	{
		camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
	}

	override function exit()
	{
		Settings.saveData();
		super.exit();
	}

	function createItem(name:String, control:Control)
	{
		var item = new ControlItem(0, 160 + (items.length * 30), name, control, player, onClick);
		item.screenCenter(X);
		items.add(item);
	}

	function onClick(id:Int, item:ControlItem)
	{
		curID = id;
		curItem = item;
		showPressText(false);
	}

	function showPressText(changingDevice:Bool)
	{
		this.changingDevice = changingDevice;
		for (item in items)
		{
			item.active = false;
		}
		pressTime = 3;
		updatePressText();
		pressText.visible = pressBG.visible = true;
	}

	function hidePressText()
	{
		for (item in items)
		{
			item.active = true;
		}
		pressTime = 0;
		pressText.visible = pressBG.visible = false;
		curItem = null;
	}

	function updatePressText()
	{
		var timeLeft = Std.string(Math.ceil(pressTime));
		if (timeLeft == '1')
			timeLeft += ' second';
		else
			timeLeft += ' seconds';

		if (changingDevice)
		{
			pressText.text = 'Press a button on the device you wish to use\nOr wait $timeLeft to cancel';
		}
		else
		{
			pressText.text = 'Press any key/button\nOr wait $timeLeft to cancel';
		}

		pressText.screenCenter();
		pressBG.setGraphicSize(Std.int(pressText.width + 4), Std.int(pressText.height + 4));
		pressBG.updateHitbox();
		pressBG.setPosition(pressText.x - 2, pressText.y - 2);
	}

	function updateDeviceText()
	{
		deviceText.text = switch (playerSettings.config.device)
		{
			case KEYBOARD:
				'Keyboard';
			case GAMEPAD(name):
				name;
			case NONE:
				'None';
		}
	}

	function changeDevice()
	{
		showPressText(true);
	}
}

class ControlItem extends FlxSpriteGroup
{
	public var name:String;
	public var control:Control;

	var callback:Int->ControlItem->Void;
	var label:FlxText;
	var buttons:Array<FlxUIButton> = [];
	var button1:FlxUIButton;
	var button2:FlxUIButton;
	var playerConfig:PlayerConfig;

	public function new(x:Float = 0, y:Float = 0, name:String, control:Control, player:Int, callback:Int->ControlItem->Void)
	{
		super(x, y);
		this.name = name;
		this.control = control;
		this.callback = callback;
		playerConfig = Settings.playerConfigs[player];

		label = new FlxText(0, 0, 150, name);
		label.setFormat('Nokia Cellphone FC Small', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(label);

		button1 = createButton(0);
		button2 = createButton(1);
	}

	public function updateLabels()
	{
		for (i in 0...buttons.length)
		{
			buttons[i].label.text = getBindText(i);
		}
	}

	function createButton(id:Int)
	{
		var button = new FlxUIButton(label.width, 0, getBindText(id), onClick.bind(id));
		if (id > 0)
		{
			button.x += button1.width;
		}
		button.resize(button.width, label.height);
		buttons.push(button);
		add(button);
		return button;
	}

	function onClick(id:Int)
	{
		callback(id, this);
	}

	function getBindText(id:Int)
	{
		var bind = playerConfig.controls.get(control)[id];
		return switch (playerConfig.device)
		{
			case KEYBOARD:
				(bind : FlxKey).toString();
			case GAMEPAD(_):
				(bind : FlxGamepadInputID).toString();
			case NONE:
				'';
		}
	}
}
