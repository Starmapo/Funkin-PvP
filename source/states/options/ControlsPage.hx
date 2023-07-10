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
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import subStates.PromptSubState;
import util.InputFormatter;

class ControlsPage extends Page
{
	static final PREVENT_KEYS:Array<FlxKey> = [
		ZERO, SEVEN, MINUS, PLUS, BACKSLASH, GRAVEACCENT, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, NUMPADZERO, NUMPADMINUS, NUMPADPLUS
	];

	var player:Int = 0;
	var items:FlxTypedGroup<ControlItem>;
	var pressBG:FlxSprite;
	var pressText:FlxText;
	var pressTime:Float = 0;
	var curItem:ControlItem;
	var curID:Int = 0;
	var settings:PlayerSettings;
	var deviceText:FlxText;
	var deviceButton:FlxUIButton;
	var changingDevice:Bool = false;
	var inputBlock:Int = 0;
	var exitButton:FlxUIButton;
	var defaultButton:FlxUIButton;
	var clearButton:FlxUIButton;
	var defaultPrompt:YesNoPrompt;
	var clearPrompt:YesNoPrompt;

	public function new(player:Int)
	{
		super();
		this.player = player;
		settings = PlayerSettings.players[player];
		rpcDetails = 'Player ${player + 1} Controls';

		items = new FlxTypedGroup();
		add(items);

		deviceText = new FlxText(5, 0, FlxG.width - 10, '', 16);
		deviceText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		updateDeviceText();
		add(deviceText);

		deviceButton = new FlxUIButton(0, deviceText.y + deviceText.height + 5, 'Change Device', changeDevicePrompt);
		deviceButton.resize(deviceButton.width * 2, deviceButton.height * 2);
		deviceButton.label.size *= 2;
		deviceButton.label.font = 'PhantomMuff 1.5';
		deviceButton.autoCenterLabel();
		deviceButton.screenCenter(X);
		add(deviceButton);

		defaultPrompt = new YesNoPrompt("Are you sure you want to reset to the default controls? This can't be undone.", function()
		{
			settings.config.controls = switch (settings.config.device)
			{
				case KEYBOARD:
					PlayerSettings.defaultKeyboardControls.copy();
				case GAMEPAD(_):
					PlayerSettings.defaultGamepadControls.copy();
				case NONE:
					PlayerSettings.defaultNoControls.copy();
			};
			reloadControls();
			updateButtons();
			CoolUtil.playConfirmSound();
		});

		defaultButton = new FlxUIButton(5, deviceButton.y, 'Reset to Default Controls', openSubState.bind(defaultPrompt));
		defaultButton.resize(defaultButton.width * 2, defaultButton.height * 2);
		defaultButton.label.font = 'PhantomMuff 1.5';
		defaultButton.label.size *= 2;
		defaultButton.autoCenterLabel();
		add(defaultButton);

		clearPrompt = new YesNoPrompt("Are you sure you want to clear your controls? This can't be undone.", function()
		{
			clearBinds();
			CoolUtil.playConfirmSound();
		});

		clearButton = new FlxUIButton(defaultButton.x, defaultButton.y + defaultButton.height + 5, 'Clear Controls', openSubState.bind(clearPrompt));
		clearButton.resize(clearButton.width * 2, clearButton.height * 2);
		clearButton.label.font = 'PhantomMuff 1.5';
		clearButton.label.size *= 2;
		clearButton.autoCenterLabel();
		add(clearButton);

		var helpText = new FlxText(5, FlxG.height - 10, FlxG.width - 10, 'Use your mouse to change the controls.', 32);
		helpText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		helpText.y -= helpText.height;
		add(helpText);

		exitButton = new FlxUIButton(FlxG.width, 0, 'X', exit);
		exitButton.resize(exitButton.height * 2, exitButton.height * 2);
		exitButton.label.size *= 2;
		exitButton.autoCenterLabel();
		exitButton.x -= exitButton.width;
		exitButton.color = FlxColor.RED;
		exitButton.label.color = FlxColor.WHITE;
		add(exitButton);

		pressBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		pressBG.alpha = 0.8;
		pressBG.scrollFactor.set();
		pressBG.visible = false;
		add(pressBG);

		pressText = new FlxText(0, 0, FlxG.width);
		pressText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		pressText.scrollFactor.set();
		pressText.visible = false;
		add(pressText);

		createItem('Left Note', NOTE_LEFT);
		createItem('Down Note', NOTE_DOWN);
		createItem('Up Note', NOTE_UP);
		createItem('Right Note', NOTE_RIGHT);
		createItem('UI Up', UI_UP);
		createItem('UI Down', UI_DOWN);
		createItem('UI Left', UI_LEFT);
		createItem('UI Right', UI_RIGHT);
		createItem('Accept', ACCEPT);
		createItem('Back', BACK);
		createItem('Pause', PAUSE);
		createItem('Reset', RESET);

		toggleControls(false);
	}

	override function update(elapsed:Float)
	{
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;

		updateDeviceText(); // in case of using a gamepad, update if it's connected or disconnected

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
					var id = FlxG.keys.firstJustReleased();
					if (id > -1)
					{
						changeDevice(KEYBOARD);
					}
					else
					{
						var gamepad = FlxG.gamepads.getFirstActiveGamepad();
						if (gamepad != null)
						{
							changeDevice(GAMEPAD(gamepad.id));
						}
					}
				}
				else
				{
					var id = settings.controls.firstJustReleased();
					var allow = switch (settings.config.device)
					{
						case KEYBOARD: !PREVENT_KEYS.contains(id);
						default: true;
					}
					if (id > -1 && allow)
					{
						var binds = settings.config.controls.get(curItem.control);

						binds[curID] = id;
						if (binds[1 - curID] == id)
							binds[1 - curID] = -1;

						curItem.updateLabels();
						hidePressText();
						reloadControls();
						inputBlock = 5;
					}
				}
			}
		}

		for (i in 0...items.length)
		{
			var item = items.members[i];
			var binds = settings.config.controls.get(item.control);
			for (i in 0...binds.length)
			{
				var bind = binds[i];
				var label = item.buttons[i].label;
				if (bind >= 0 && settings.controls.pressedID(bind))
				{
					label.color = 0x00BF00;
				}
				else
				{
					label.color = 0x333333;
				}
			}
		}

		super.update(elapsed);

		if (inputBlock > 0)
			inputBlock--;
	}

	override function destroy()
	{
		super.destroy();
		items = null;
		pressBG = null;
		pressText = null;
		curItem = null;
		settings = null;
		deviceText = null;
		deviceButton = null;
		exitButton = null;
		defaultButton = null;
		clearButton = null;
		defaultPrompt = FlxDestroyUtil.destroy(defaultPrompt);
		clearPrompt = FlxDestroyUtil.destroy(clearPrompt);
	}

	override function onAppear()
	{
		camFollow.y = FlxG.height / 2;
		toggleControls(true);
	}

	override function exit()
	{
		var canExit = true;
		if (settings.config.device != NONE)
		{
			for (item in items)
			{
				if (item.button1.label.text == '[?]')
				{
					canExit = false;
					FlxTween.cancelTweensOf(item.button1);
					FlxTween.color(item.button1, 1, FlxColor.WHITE, FlxColor.RED, {
						onComplete: function(_)
						{
							FlxTween.color(item.button1, 1, FlxColor.RED, FlxColor.WHITE);
						}
					});
				}
			}
		}

		if (canExit)
		{
			toggleControls(false);
			Settings.saveData();
			super.exit();
			CoolUtil.playCancelSound();
		}
	}

	override function updateControls() {}

	function createItem(name:String, control:Control)
	{
		var item = new ControlItem(0, 120 + (items.length * 45), name, control, player, onClick);
		item.screenCenter(X);
		items.add(item);
	}

	function onClick(id:Int, item:ControlItem)
	{
		if (settings.config.device != NONE)
		{
			curID = id;
			curItem = item;
			showPressText(false);
		}
		else
		{
			FlxTween.cancelTweensOf(deviceButton);
			FlxTween.color(deviceButton, 1, FlxColor.WHITE, FlxColor.RED, {
				onComplete: function(_)
				{
					FlxTween.color(deviceButton, 1, FlxColor.RED, FlxColor.WHITE);
				}
			});
		}
	}

	function showPressText(changingDevice:Bool)
	{
		this.changingDevice = changingDevice;
		pressTime = 3;
		updatePressText();
		pressText.visible = pressBG.visible = true;
		toggleControls(false);
	}

	function hidePressText()
	{
		pressTime = 0;
		pressText.visible = pressBG.visible = false;
		curItem = null;
		toggleControls(true);
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
		pressBG.setGraphicSize(FlxG.width, pressText.height + 4);
		pressBG.updateHitbox();
		pressBG.y = pressText.y - 2;
	}

	function updateDeviceText()
	{
		switch (settings.config.device)
		{
			case KEYBOARD:
				deviceText.text = 'Keyboard';
			case GAMEPAD(id):
				var gamepad = FlxG.gamepads.getByID(id);
				if (gamepad != null)
				{
					deviceText.text = 'Gamepad $id (${gamepad.name})';
				}
				else
				{
					deviceText.text = 'Gamepad $id (DISCONNECTED)';
				}
			case NONE:
				deviceText.text = 'None';
		}
	}

	function changeDevicePrompt()
	{
		showPressText(true);
	}

	function changeDevice(device:PlayerConfigDevice)
	{
		var lastDevice = settings.config.device;
		settings.config.device = device;
		updateDeviceText();
		hidePressText();
		if (!device.equals(lastDevice))
		{
			clearBinds();
		}
		reloadControls();
		inputBlock = 5;
		CoolUtil.playConfirmSound();
	}

	function clearBinds()
	{
		var controls = settings.config.controls;
		for (key in controls.keys())
		{
			controls.set(key, [-1, -1]);
		}
		reloadControls();
		updateButtons();
	}

	function updateButtons()
	{
		for (item in items)
		{
			item.updateLabels();
		}
	}

	function reloadControls()
	{
		settings.controls.loadFromConfig(settings.config);
	}

	function toggleControls(enabled:Bool)
	{
		controlsEnabled = enabled;
		for (item in items)
		{
			item.active = enabled;
		}
		deviceButton.active = enabled;
		exitButton.active = enabled;
	}
}

class ControlItem extends FlxSpriteGroup
{
	public var name:String;
	public var control:Control;
	public var label:FlxText;
	public var buttons:Array<FlxUIButton> = [];
	public var button1:FlxUIButton;
	public var button2:FlxUIButton;

	var callback:Int->ControlItem->Void;
	var settings:PlayerSettings;

	public function new(x:Float = 0, y:Float = 0, name:String, control:Control, player:Int, callback:Int->ControlItem->Void)
	{
		super(x, y);
		this.name = name;
		this.control = control;
		this.callback = callback;
		settings = PlayerSettings.players[player];

		label = new FlxText(0, 0, 150, name);
		label.setFormat('PhantomMuff 1.5', 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
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
		button.resize(button.width * 2, label.height);
		button.label.size = 24;
		button.label.font = 'PhantomMuff 1.5';
		button.autoCenterLabel();
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
		var bind = settings.config.controls.get(control)[id];
		return InputFormatter.format(bind, settings);
	}
}
