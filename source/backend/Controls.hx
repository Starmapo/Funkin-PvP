package backend;

import backend.settings.PlayerConfig;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class Controls
{
	public static var players:Array<Controls> = [];
	
	public static function init()
	{	
		if (players.length > 0)
			return;
		
		for (i in 0...2)
			players.push(new Controls(i));
	}
	
	public static function anyJustPressed(action:Action)
	{
		for (player in players)
			if (player.justPressed(action))
				return true;
				
		return false;
	}
	
	public static function anyPressed(action:Action)
	{
		for (player in players)
			if (player.pressed(action))
				return true;
				
		return false;
	}
	
	public static function anyJustReleased(action:Action)
	{
		for (player in players)
			if (player.justReleased(action))
				return true;
				
		return false;
	}
	
	public static function anyReleased(action:Action)
	{
		for (player in players)
			if (player.released(action))
				return true;
				
		return false;
	}
	
	public static function anyCheckStatus(action:Action, state:FlxInputState)
	{
		for (player in players)
			if (player.checkStatus(action, state))
				return true;
				
		return false;
	}
	
	public static function playerJustPressed(player:Int, action:Action)
	{
		return players[player].justPressed(action);
	}
	
	public static function playerPressed(player:Int, action:Action)
	{
		return players[player].pressed(action);
	}
	
	public static function playerJustReleased(player:Int, action:Action)
	{
		return players[player].justReleased(action);
	}
	
	public static function playerReleased(player:Int, action:Action)
	{
		return players[player].released(action);
	}
	
	public static function playerCheckStatus(player:Int, action:Action, state:FlxInputState)
	{
		return players[player].checkStatus(action, state);
	}
	
	public static function anyInputJustPressed():Bool
	{
		return (FlxG.keys.justPressed.ANY || FlxG.gamepads.anyButton(JUST_PRESSED));
	}
	
	public static function anyInputPressed():Bool
	{
		return (FlxG.keys.pressed.ANY || FlxG.gamepads.anyButton(PRESSED));
	}
	
	public static function getDefaultControls(device:PlayerConfigDevice):Map<Action, Array<Int>>
	{
		return switch (device)
		{
			case KEYBOARD:
				[
					NOTE(1, 0) => [FlxKey.SPACE],
					
					NOTE(2, 0) => [FlxKey.F],
					NOTE(2, 1) => [FlxKey.J],
					
					NOTE(3, 0) => [FlxKey.F],
					NOTE(3, 1) => [FlxKey.SPACE],
					NOTE(3, 2) => [FlxKey.J],
					
					NOTE(4, 0) => [FlxKey.D],
					NOTE(4, 1) => [FlxKey.F],
					NOTE(4, 2) => [FlxKey.J],
					NOTE(4, 3) => [FlxKey.K],
					
					NOTE(5, 0) => [FlxKey.D],
					NOTE(5, 1) => [FlxKey.F],
					NOTE(5, 2) => [FlxKey.SPACE],
					NOTE(5, 3) => [FlxKey.J],
					NOTE(5, 4) => [FlxKey.K],
					
					NOTE(6, 0) => [FlxKey.S],
					NOTE(6, 1) => [FlxKey.D],
					NOTE(6, 2) => [FlxKey.F],
					NOTE(6, 3) => [FlxKey.J],
					NOTE(6, 4) => [FlxKey.K],
					NOTE(6, 5) => [FlxKey.L],
					
					NOTE(7, 0) => [FlxKey.S],
					NOTE(7, 1) => [FlxKey.D],
					NOTE(7, 2) => [FlxKey.F],
					NOTE(7, 3) => [FlxKey.SPACE],
					NOTE(7, 4) => [FlxKey.J],
					NOTE(7, 5) => [FlxKey.K],
					NOTE(7, 6) => [FlxKey.L],
					
					NOTE(8, 0) => [FlxKey.A],
					NOTE(8, 1) => [FlxKey.S],
					NOTE(8, 2) => [FlxKey.D],
					NOTE(8, 3) => [FlxKey.F],
					NOTE(8, 4) => [FlxKey.J],
					NOTE(8, 5) => [FlxKey.K],
					NOTE(8, 6) => [FlxKey.L],
					NOTE(8, 7) => [FlxKey.SEMICOLON],
					
					NOTE(9, 0) => [FlxKey.A],
					NOTE(9, 1) => [FlxKey.S],
					NOTE(9, 2) => [FlxKey.D],
					NOTE(9, 3) => [FlxKey.F],
					NOTE(9, 4) => [FlxKey.SPACE],
					NOTE(9, 5) => [FlxKey.J],
					NOTE(9, 6) => [FlxKey.K],
					NOTE(9, 7) => [FlxKey.L],
					NOTE(9, 8) => [FlxKey.SEMICOLON],
					
					NOTE(10, 0) => [FlxKey.A],
					NOTE(10, 1) => [FlxKey.S],
					NOTE(10, 2) => [FlxKey.D],
					NOTE(10, 3) => [FlxKey.F],
					NOTE(10, 4) => [FlxKey.V],
					NOTE(10, 5) => [FlxKey.N],
					NOTE(10, 6) => [FlxKey.J],
					NOTE(10, 7) => [FlxKey.K],
					NOTE(10, 8) => [FlxKey.L],
					NOTE(10, 9) => [FlxKey.SEMICOLON],
					
					UI_UP => [FlxKey.W, FlxKey.UP],
					UI_LEFT => [FlxKey.A, FlxKey.LEFT],
					UI_RIGHT => [FlxKey.D, FlxKey.RIGHT],
					UI_DOWN => [FlxKey.S, FlxKey.DOWN],
					
					ACCEPT => [FlxKey.SPACE, FlxKey.ENTER],
					BACK => [FlxKey.BACKSPACE, FlxKey.ESCAPE],
					PAUSE => [FlxKey.ENTER, FlxKey.ESCAPE],
					RESET => [FlxKey.R]
				];
			case GAMEPAD(_):
				[
					NOTE(2, 0) => [FlxGamepadInputID.LEFT_SHOULDER],
					NOTE(2, 1) => [FlxGamepadInputID.RIGHT_SHOULDER],
					
					NOTE(4, 0) => [FlxGamepadInputID.LEFT_TRIGGER],
					NOTE(4, 1) => [FlxGamepadInputID.LEFT_SHOULDER],
					NOTE(4, 2) => [FlxGamepadInputID.RIGHT_SHOULDER],
					NOTE(4, 3) => [FlxGamepadInputID.RIGHT_TRIGGER],
					
					UI_UP => [FlxGamepadInputID.LEFT_STICK_DIGITAL_UP, FlxGamepadInputID.DPAD_UP],
					UI_LEFT => [FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT, FlxGamepadInputID.DPAD_LEFT],
					UI_RIGHT => [FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT, FlxGamepadInputID.DPAD_RIGHT],
					UI_DOWN => [FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN, FlxGamepadInputID.DPAD_DOWN],
					
					ACCEPT => [FlxGamepadInputID.A],
					BACK => [FlxGamepadInputID.B],
					PAUSE => [FlxGamepadInputID.START],
					RESET => [FlxGamepadInputID.X]
				];
			default: [];
		}
	}
	
	public var player:Int;
	public var config(get, never):PlayerConfig;
	public var gamepad(get, never):FlxGamepad;
	
	public function new(player:Int)
	{
		this.player = player;
	}
	
	public function justPressed(action:Action)
	{
		return checkStatus(action, JUST_PRESSED);
	}
	
	public function pressed(action:Action)
	{
		return checkStatus(action, PRESSED);
	}
	
	public function justReleased(action:Action)
	{
		return checkStatus(action, JUST_RELEASED);
	}
	
	public function released(action:Action)
	{
		return checkStatus(action, RELEASED);
	}
	
	public function checkStatus(action:Action, state:FlxInputState)
	{
		if (config.device == NONE || (config.device.match(GAMEPAD(_)) && gamepad == null))
			return false;
			
		var keys = config.controls.get(action);
		if (keys != null)
		{
			for (key in keys)
			{
				if (checkKeyStatus(key, state))
					return true;
			}
		}
		
		return false;
	}
	
	function checkKeyStatus(key:Int, state:FlxInputState)
	{
		if (key >= 0)
		{
			return switch (config.device)
			{
				case KEYBOARD: FlxG.keys.checkStatus(key, state);
				case GAMEPAD(_): gamepad.checkStatus(key, state);
				default: false;
			}
		}
		
		return false;
	}
	
	function get_config()
	{
		return Settings.playerConfigs[player];
	}
	
	function get_gamepad()
	{
		return switch (config.device)
		{
			case GAMEPAD(id): FlxG.gamepads.getByID(id);
			default: null;
		}
	}
}

enum Action
{
	NOTE(keyAmount:Int, lane:Int);
	UI_UP;
	UI_LEFT;
	UI_RIGHT;
	UI_DOWN;
	ACCEPT;
	BACK;
	PAUSE;
	RESET;
}
