package data;

import data.Controls.Action;
import data.Controls.Control;
import data.PlayerConfig.PlayerConfigDevice;
import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class PlayerSettings
{
	public static var players(default, never):Array<PlayerSettings> = [];
	public static var defaultKeyboardControls(default, never):Map<Control, Array<Int>> = [
		NOTE_LEFT => [FlxKey.A, FlxKey.LEFT],
		NOTE_DOWN => [FlxKey.S, FlxKey.DOWN],
		NOTE_UP => [FlxKey.K, FlxKey.UP],
		NOTE_RIGHT => [FlxKey.L, FlxKey.RIGHT],
		UI_UP => [FlxKey.W, FlxKey.UP],
		UI_LEFT => [FlxKey.A, FlxKey.LEFT],
		UI_RIGHT => [FlxKey.D, FlxKey.RIGHT],
		UI_DOWN => [FlxKey.S, FlxKey.DOWN],
		ACCEPT => [FlxKey.SPACE, FlxKey.ENTER],
		BACK => [FlxKey.BACKSPACE, FlxKey.ESCAPE],
		PAUSE => [FlxKey.ENTER, FlxKey.ESCAPE],
		RESET => [FlxKey.R, FlxKey.NONE],
	];
	public static var defaultGamepadControls(default, never):Map<Control, Array<Int>> = [
		NOTE_LEFT => [FlxGamepadInputID.LEFT_TRIGGER, FlxGamepadInputID.NONE],
		NOTE_DOWN => [FlxGamepadInputID.LEFT_SHOULDER, FlxGamepadInputID.NONE],
		NOTE_UP => [FlxGamepadInputID.RIGHT_SHOULDER, FlxGamepadInputID.NONE],
		NOTE_RIGHT => [FlxGamepadInputID.RIGHT_TRIGGER, FlxGamepadInputID.NONE],
		UI_UP => [FlxGamepadInputID.LEFT_STICK_DIGITAL_UP, FlxGamepadInputID.DPAD_UP],
		UI_LEFT => [FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT, FlxGamepadInputID.DPAD_LEFT],
		UI_RIGHT => [FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT, FlxGamepadInputID.DPAD_RIGHT],
		UI_DOWN => [FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN, FlxGamepadInputID.DPAD_DOWN],
		ACCEPT => [FlxGamepadInputID.A, FlxGamepadInputID.NONE],
		BACK => [FlxGamepadInputID.B, FlxGamepadInputID.NONE],
		PAUSE => [FlxGamepadInputID.START, FlxGamepadInputID.NONE],
		RESET => [FlxGamepadInputID.X, FlxGamepadInputID.NONE],
	];
	public static var defaultNoControls(default, never):Map<Control, Array<Int>> = [
		NOTE_LEFT => [-1, -1], NOTE_DOWN => [-1, -1], NOTE_UP => [-1, -1], NOTE_RIGHT => [-1, -1], UI_UP => [-1, -1], UI_LEFT => [-1, -1],
		 UI_RIGHT => [-1, -1],   UI_DOWN => [-1, -1],  ACCEPT => [-1, -1],       BACK => [-1, -1], PAUSE => [-1, -1],   RESET => [-1, -1],
	];

	public var id(default, null):Int;
	public var config(default, null):PlayerConfig;
	public var controls(default, null):Controls;

	function new(id:Int)
	{
		this.id = id;
		this.config = Settings.playerConfigs[id];
		this.controls = new Controls('player$id', config);
	}

	public static function init()
	{
		initSaveData();

		for (i in 0...2)
		{
			var player = new PlayerSettings(i);
			players.push(player);
		}

		FlxG.gamepads.deviceConnected.add(onGamepadConnected);
	}

	public static function checkAction(action:Action)
	{
		for (player in players)
		{
			if (player.controls.checkByName(action))
				return true;
		}

		return false;
	}

	public static function checkPlayerAction(player:Int, action:Action)
	{
		var player = players[player];
		if (player != null && player.controls.checkByName(action))
			return true;

		return false;
	}

	public static function checkActions(actions:Array<Action>)
	{
		for (action in actions)
		{
			if (checkAction(action))
			{
				return true;
			}
		}
		return false;
	}

	public static function checkPlayerActions(player:Int, actions:Array<Action>)
	{
		for (action in actions)
		{
			if (checkPlayerAction(player, action))
			{
				return true;
			}
		}
		return false;
	}

	public static function anyPressed()
	{
		for (player in players)
		{
			if (player.controls.anyPressed())
				return true;
		}

		return false;
	}

	public static function anyJustPressed()
	{
		for (player in players)
		{
			if (player.controls.anyJustPressed())
				return true;
		}

		return false;
	}

	public static function anyJustReleased()
	{
		for (player in players)
		{
			if (player.controls.anyJustReleased())
				return true;
		}

		return false;
	}

	static function onGamepadConnected(gamepad:FlxGamepad)
	{
		var id = gamepad.id;

		for (i in 0...players.length)
		{
			var player = players[i];
			if (player.config.device.equals(GAMEPAD(id)) && !player.controls.controlsAdded)
			{
				player.controls.loadFromConfig(player.config);
			}
		}
	}

	static function initSaveData()
	{
		if (Settings.playerConfigs == null)
		{
			var playerConfigs:Array<PlayerConfig> = [createDefaultConfig(KEYBOARD, defaultKeyboardControls.copy())];

			var foundGamepad:Bool = false;
			for (i in 0...FlxG.gamepads.numActiveGamepads)
			{
				var gamepad = FlxG.gamepads.getByID(i);
				if (gamepad != null)
				{
					playerConfigs.push(createDefaultConfig(GAMEPAD(gamepad.id), defaultGamepadControls.copy()));
					foundGamepad = true;
					break;
				}
			}
			if (!foundGamepad)
				playerConfigs.push(createDefaultConfig(NONE, defaultNoControls.copy()));

			Settings.playerConfigs = playerConfigs;
			Settings.saveData();
		}
	}

	static function createDefaultConfig(device:PlayerConfigDevice, controls:Map<Control, Array<Int>>):PlayerConfig
	{
		return {
			device: device,
			controls: controls,
			downScroll: false,
			scrollSpeed: 0.75
		};
	}
}
