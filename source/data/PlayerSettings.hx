package data;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class PlayerSettings
{
	public static var players(default, never):Array<PlayerSettings> = [];

	public var id(default, null):Int;
	public var config(default, null):PlayerConfig;
	public var controls(default, null):Controls;

	function new(id:Int)
	{
		this.id = id;
		this.config = FlxG.save.data.playerConfigs[id];
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

	static function onGamepadConnected(gamepad:FlxGamepad)
	{
		var name = gamepad.name;
		if (name == null)
			return;

		for (i in 0...players.length)
		{
			var player = players[i];
			if (player.config.device.equals(Gamepad(name)) && !player.controls.controlsAdded)
			{
				player.controls.loadFromConfig(player.config);
			}
		}
	}

	static function initSaveData()
	{
		if (FlxG.save.data.playerConfigs == null)
		{
			var playerConfigs:Array<PlayerConfig> = [
				{
					device: Keyboard,
					controls: [
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
					],
					downScroll: false
				}
			];

			var foundGamepad:Bool = false;
			for (i in 0...FlxG.gamepads.numActiveGamepads)
			{
				var gamepad = FlxG.gamepads.getByID(i);
				if (gamepad != null)
				{
					playerConfigs.push({
						device: Gamepad(gamepad.name),
						controls: [
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
							RESET => [FlxGamepadInputID.Y, FlxGamepadInputID.NONE],
						],
						downScroll: false
					});
					foundGamepad = true;
					break;
				}
			}
			if (!foundGamepad)
			{
				playerConfigs.push({
					device: None,
					controls: [
						NOTE_LEFT => [-1, -1], NOTE_DOWN => [-1, -1], NOTE_UP => [-1, -1], NOTE_RIGHT => [-1, -1], UI_UP => [-1, -1], UI_LEFT => [-1, -1],
						 UI_RIGHT => [-1, -1],   UI_DOWN => [-1, -1],  ACCEPT => [-1, -1],       BACK => [-1, -1], PAUSE => [-1, -1],   RESET => [-1, -1],
					],
					downScroll: false
				});
			}

			FlxG.save.data.playerConfigs = playerConfigs;
			FlxG.save.flush();
		}
	}
}
