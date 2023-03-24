package data;

import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
	NOTE_LEFT;
	NOTE_DOWN;
	NOTE_UP;
	NOTE_RIGHT;
	UI_UP;
	UI_LEFT;
	UI_RIGHT;
	UI_DOWN;
	ACCEPT;
	BACK;
	PAUSE;
	RESET;
}

enum abstract Action(String) to String from String
{
	var UI_UP = "ui_up";
	var UI_LEFT = "ui_left";
	var UI_RIGHT = "ui_right";
	var UI_DOWN = "ui_down";
	var UI_UP_P = "ui_up-press";
	var UI_LEFT_P = "ui_left-press";
	var UI_RIGHT_P = "ui_right-press";
	var UI_DOWN_P = "ui_down-press";
	var UI_UP_R = "ui_up-release";
	var UI_LEFT_R = "ui_left-release";
	var UI_RIGHT_R = "ui_right-release";
	var UI_DOWN_R = "ui_down-release";
	var NOTE_UP = "note_up";
	var NOTE_LEFT = "note_left";
	var NOTE_RIGHT = "note_right";
	var NOTE_DOWN = "note_down";
	var NOTE_UP_P = "note_up-press";
	var NOTE_LEFT_P = "note_left-press";
	var NOTE_RIGHT_P = "note_right-press";
	var NOTE_DOWN_P = "note_down-press";
	var NOTE_UP_R = "note_up-release";
	var NOTE_LEFT_R = "note_left-release";
	var NOTE_RIGHT_R = "note_right-release";
	var NOTE_DOWN_R = "note_down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	var ACCEPT_P = "accept-press";
	var BACK_P = "back-press";
	var PAUSE_P = "pause-press";
	var RESET_P = "reset-press";
	var ACCEPT_R = "accept-release";
	var BACK_R = "back-release";
	var PAUSE_R = "pause-release";
	var RESET_R = "reset-release";
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
	public static function getDialogueName(action:FlxActionDigital):String
	{
		var input = action.inputs[0];
		return switch input.device
		{
			case KEYBOARD: return '[${(input.inputID : FlxKey)}]';
			case GAMEPAD: return '(${(input.inputID : FlxGamepadInputID)})';
			case device: throw 'unhandled device: $device';
		}
	}

	inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
		{
			if (key != NONE)
				action.addKey(key, state);
		}
	}

	inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state:FlxInputState, id:Int)
	{
		for (button in buttons)
		{
			if (button != NONE)
				action.addGamepad(button, state, id);
		}
	}

	var _ui_up = new FlxActionDigital(Action.UI_UP);
	var _ui_left = new FlxActionDigital(Action.UI_LEFT);
	var _ui_right = new FlxActionDigital(Action.UI_RIGHT);
	var _ui_down = new FlxActionDigital(Action.UI_DOWN);
	var _ui_upP = new FlxActionDigital(Action.UI_UP_P);
	var _ui_leftP = new FlxActionDigital(Action.UI_LEFT_P);
	var _ui_rightP = new FlxActionDigital(Action.UI_RIGHT_P);
	var _ui_downP = new FlxActionDigital(Action.UI_DOWN_P);
	var _ui_upR = new FlxActionDigital(Action.UI_UP_R);
	var _ui_leftR = new FlxActionDigital(Action.UI_LEFT_R);
	var _ui_rightR = new FlxActionDigital(Action.UI_RIGHT_R);
	var _ui_downR = new FlxActionDigital(Action.UI_DOWN_R);
	var _note_up = new FlxActionDigital(Action.NOTE_UP);
	var _note_left = new FlxActionDigital(Action.NOTE_LEFT);
	var _note_right = new FlxActionDigital(Action.NOTE_RIGHT);
	var _note_down = new FlxActionDigital(Action.NOTE_DOWN);
	var _note_upP = new FlxActionDigital(Action.NOTE_UP_P);
	var _note_leftP = new FlxActionDigital(Action.NOTE_LEFT_P);
	var _note_rightP = new FlxActionDigital(Action.NOTE_RIGHT_P);
	var _note_downP = new FlxActionDigital(Action.NOTE_DOWN_P);
	var _note_upR = new FlxActionDigital(Action.NOTE_UP_R);
	var _note_leftR = new FlxActionDigital(Action.NOTE_LEFT_R);
	var _note_rightR = new FlxActionDigital(Action.NOTE_RIGHT_R);
	var _note_downR = new FlxActionDigital(Action.NOTE_DOWN_R);
	var _accept = new FlxActionDigital(Action.ACCEPT);
	var _back = new FlxActionDigital(Action.BACK);
	var _pause = new FlxActionDigital(Action.PAUSE);
	var _reset = new FlxActionDigital(Action.RESET);
	var _acceptP = new FlxActionDigital(Action.ACCEPT_P);
	var _backP = new FlxActionDigital(Action.BACK_P);
	var _pauseP = new FlxActionDigital(Action.PAUSE_P);
	var _resetP = new FlxActionDigital(Action.RESET_P);
	var _acceptR = new FlxActionDigital(Action.ACCEPT_R);
	var _backR = new FlxActionDigital(Action.BACK_R);
	var _pauseR = new FlxActionDigital(Action.PAUSE_R);
	var _resetR = new FlxActionDigital(Action.RESET_R);

	public var UI_UP(get, never):Bool;

	inline function get_UI_UP()
		return _ui_up.check();

	public var UI_LEFT(get, never):Bool;

	inline function get_UI_LEFT()
		return _ui_left.check();

	public var UI_RIGHT(get, never):Bool;

	inline function get_UI_RIGHT()
		return _ui_right.check();

	public var UI_DOWN(get, never):Bool;

	inline function get_UI_DOWN()
		return _ui_down.check();

	public var UI_UP_P(get, never):Bool;

	inline function get_UI_UP_P()
		return _ui_upP.check();

	public var UI_LEFT_P(get, never):Bool;

	inline function get_UI_LEFT_P()
		return _ui_leftP.check();

	public var UI_RIGHT_P(get, never):Bool;

	inline function get_UI_RIGHT_P()
		return _ui_rightP.check();

	public var UI_DOWN_P(get, never):Bool;

	inline function get_UI_DOWN_P()
		return _ui_downP.check();

	public var UI_UP_R(get, never):Bool;

	inline function get_UI_UP_R()
		return _ui_upR.check();

	public var UI_LEFT_R(get, never):Bool;

	inline function get_UI_LEFT_R()
		return _ui_leftR.check();

	public var UI_RIGHT_R(get, never):Bool;

	inline function get_UI_RIGHT_R()
		return _ui_rightR.check();

	public var UI_DOWN_R(get, never):Bool;

	inline function get_UI_DOWN_R()
		return _ui_downR.check();

	public var NOTE_UP(get, never):Bool;

	inline function get_NOTE_UP()
		return _note_up.check();

	public var NOTE_LEFT(get, never):Bool;

	inline function get_NOTE_LEFT()
		return _note_left.check();

	public var NOTE_RIGHT(get, never):Bool;

	inline function get_NOTE_RIGHT()
		return _note_right.check();

	public var NOTE_DOWN(get, never):Bool;

	inline function get_NOTE_DOWN()
		return _note_down.check();

	public var NOTE_UP_P(get, never):Bool;

	inline function get_NOTE_UP_P()
		return _note_upP.check();

	public var NOTE_LEFT_P(get, never):Bool;

	inline function get_NOTE_LEFT_P()
		return _note_leftP.check();

	public var NOTE_RIGHT_P(get, never):Bool;

	inline function get_NOTE_RIGHT_P()
		return _note_rightP.check();

	public var NOTE_DOWN_P(get, never):Bool;

	inline function get_NOTE_DOWN_P()
		return _note_downP.check();

	public var NOTE_UP_R(get, never):Bool;

	inline function get_NOTE_UP_R()
		return _note_upR.check();

	public var NOTE_LEFT_R(get, never):Bool;

	inline function get_NOTE_LEFT_R()
		return _note_leftR.check();

	public var NOTE_RIGHT_R(get, never):Bool;

	inline function get_NOTE_RIGHT_R()
		return _note_rightR.check();

	public var NOTE_DOWN_R(get, never):Bool;

	inline function get_NOTE_DOWN_R()
		return _note_downR.check();

	public var ACCEPT(get, never):Bool;

	inline function get_ACCEPT()
		return _accept.check();

	public var BACK(get, never):Bool;

	inline function get_BACK()
		return _back.check();

	public var PAUSE(get, never):Bool;

	inline function get_PAUSE()
		return _pause.check();

	public var RESET(get, never):Bool;

	inline function get_RESET()
		return _reset.check();

	public var ACCEPT_P(get, never):Bool;

	inline function get_ACCEPT_P()
		return _acceptP.check();

	public var BACK_P(get, never):Bool;

	inline function get_BACK_P()
		return _backP.check();

	public var PAUSE_P(get, never):Bool;

	inline function get_PAUSE_P()
		return _pauseP.check();

	public var RESET_P(get, never):Bool;

	inline function get_RESET_P()
		return _resetP.check();

	public var ACCEPT_R(get, never):Bool;

	inline function get_ACCEPT_R()
		return _acceptR.check();

	public var BACK_R(get, never):Bool;

	inline function get_BACK_R()
		return _backR.check();

	public var PAUSE_R(get, never):Bool;

	inline function get_PAUSE_R()
		return _pauseR.check();

	public var RESET_R(get, never):Bool;

	inline function get_RESET_R()
		return _resetR.check();

	public var config(default, null):PlayerConfig;
	public var controlsAdded(default, null):Bool = false;
	public var gamepad(default, null):FlxGamepad;

	var byName:Map<String, FlxActionDigital> = new Map<String, FlxActionDigital>();

	public function new(name:String, config:PlayerConfig)
	{
		super(name);

		add(_ui_up);
		add(_ui_left);
		add(_ui_right);
		add(_ui_down);
		add(_ui_upP);
		add(_ui_leftP);
		add(_ui_rightP);
		add(_ui_downP);
		add(_ui_upR);
		add(_ui_leftR);
		add(_ui_rightR);
		add(_ui_downR);
		add(_note_up);
		add(_note_left);
		add(_note_right);
		add(_note_down);
		add(_note_upP);
		add(_note_leftP);
		add(_note_rightP);
		add(_note_downP);
		add(_note_upR);
		add(_note_leftR);
		add(_note_rightR);
		add(_note_downR);
		add(_accept);
		add(_back);
		add(_pause);
		add(_reset);
		add(_acceptP);
		add(_backP);
		add(_pauseP);
		add(_resetP);
		add(_acceptR);
		add(_backR);
		add(_pauseR);
		add(_resetR);

		for (action in digitalActions)
			byName[action.name] = action;

		loadFromConfig(config);
	}

	public function checkByName(name:Action):Bool
	{
		if (!byName.exists(name))
			throw 'Invalid name: $name';

		return byName[name].check();
	}

	public function getDialogueNameFromControl(control:Control)
	{
		return getDialogueName(getActionFromControl(control));
	}

	public function getActionFromControl(control:Control):FlxActionDigital
	{
		return switch (control)
		{
			case UI_UP: _ui_up;
			case UI_DOWN: _ui_down;
			case UI_LEFT: _ui_left;
			case UI_RIGHT: _ui_right;
			case NOTE_UP: _note_up;
			case NOTE_DOWN: _note_down;
			case NOTE_LEFT: _note_left;
			case NOTE_RIGHT: _note_right;
			case ACCEPT: _accept;
			case BACK: _back;
			case PAUSE: _pause;
			case RESET: _reset;
		}
	}

	public function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		forEachBound(control, function(action, state) addKeys(action, keys, state));
	}

	public function bindButtons(control:Control, id:Int, buttons:Array<FlxGamepadInputID>)
	{
		forEachBound(control, function(action, state) addButtons(action, buttons, state, id));
	}

	public function loadFromConfig(config:PlayerConfig)
	{
		if (config == null)
		{
			FlxG.log.error("Can't load \"null\" player configuration.");
			return;
		}

		reset();

		this.config = config;
		switch (config.device)
		{
			case KEYBOARD:
				for (control => binds in config.controls)
				{
					bindKeys(control, binds);
				}
				controlsAdded = true;
			case GAMEPAD(id):
				var gamepad = FlxG.gamepads.getByID(id);
				if (gamepad != null)
				{
					this.gamepad = gamepad;
					for (control => binds in config.controls)
					{
						bindButtons(control, gamepad.id, binds);
					}
					controlsAdded = true;
				}
				else
				{
					FlxG.log.warn('Couldn\'t find gamepad \"$id\".');
				}
			case NONE:
		}
	}

	public function reset()
	{
		for (action in digitalActions)
		{
			action.removeAll();
		}

		controlsAdded = false;
		gamepad = null;
	}

	public function anyPressed()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.pressed.ANY;
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.pressed.ANY;
				return false;
			case NONE:
				return false;
		}
	}

	public function anyJustPressed()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.justPressed.ANY;
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.justPressed.ANY;
				return false;
			case NONE:
				return false;
		}
	}

	public function anyJustReleased()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.justReleased.ANY;
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.justReleased.ANY;
				return false;
			case NONE:
				return false;
		}
	}

	public function firstPressed()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.firstPressed();
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.firstPressedID();
				return -1;
			case NONE:
				return -1;
		}
	}

	public function firstJustPressed()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.firstJustPressed();
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.firstJustPressedID();
				return -1;
			case NONE:
				return -1;
		}
	}

	public function firstJustReleased()
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.firstJustReleased();
			case GAMEPAD(_):
				if (gamepad != null)
					return gamepad.firstJustReleasedID();
				return -1;
			case NONE:
				return -1;
		}
	}

	public function pressedID(id:Int)
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.checkStatus(id, PRESSED);
			case GAMEPAD(_):
				try
				{
					if (gamepad != null)
						return gamepad.checkStatus(id, PRESSED);
					return false;
				}
				catch (e)
				{
					trace(e);
					return false;
				}
			case NONE:
				return false;
		}
	}

	public function justPressedID(id:Int)
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.checkStatus(id, JUST_PRESSED);
			case GAMEPAD(_):
				try
				{
					if (gamepad != null)
						return gamepad.checkStatus(id, JUST_PRESSED);
					return false;
				}
				catch (e)
				{
					trace(e);
					return false;
				}
			case NONE:
				return false;
		}
	}

	public function justReleasedID(id:Int)
	{
		switch (config.device)
		{
			case KEYBOARD:
				return FlxG.keys.checkStatus(id, JUST_RELEASED);
			case GAMEPAD(_):
				try
				{
					if (gamepad != null)
						return gamepad.checkStatus(id, JUST_RELEASED);
					return false;
				}
				catch (e)
				{
					trace(e);
					return false;
				}
			case NONE:
				return false;
		}
	}

	function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
	{
		switch (control)
		{
			case UI_UP:
				func(_ui_up, PRESSED);
				func(_ui_upP, JUST_PRESSED);
				func(_ui_upR, JUST_RELEASED);
			case UI_LEFT:
				func(_ui_left, PRESSED);
				func(_ui_leftP, JUST_PRESSED);
				func(_ui_leftR, JUST_RELEASED);
			case UI_RIGHT:
				func(_ui_right, PRESSED);
				func(_ui_rightP, JUST_PRESSED);
				func(_ui_rightR, JUST_RELEASED);
			case UI_DOWN:
				func(_ui_down, PRESSED);
				func(_ui_downP, JUST_PRESSED);
				func(_ui_downR, JUST_RELEASED);
			case NOTE_UP:
				func(_note_up, PRESSED);
				func(_note_upP, JUST_PRESSED);
				func(_note_upR, JUST_RELEASED);
			case NOTE_LEFT:
				func(_note_left, PRESSED);
				func(_note_leftP, JUST_PRESSED);
				func(_note_leftR, JUST_RELEASED);
			case NOTE_RIGHT:
				func(_note_right, PRESSED);
				func(_note_rightP, JUST_PRESSED);
				func(_note_rightR, JUST_RELEASED);
			case NOTE_DOWN:
				func(_note_down, PRESSED);
				func(_note_downP, JUST_PRESSED);
				func(_note_downR, JUST_RELEASED);
			case ACCEPT:
				func(_accept, PRESSED);
				func(_acceptP, JUST_PRESSED);
				func(_acceptR, JUST_RELEASED);
			case BACK:
				func(_back, PRESSED);
				func(_backP, JUST_PRESSED);
				func(_backR, JUST_RELEASED);
			case PAUSE:
				func(_pause, PRESSED);
				func(_pauseP, JUST_PRESSED);
				func(_pauseR, JUST_RELEASED);
			case RESET:
				func(_reset, PRESSED);
				func(_resetP, JUST_PRESSED);
				func(_resetR, JUST_RELEASED);
		}
	}
}
