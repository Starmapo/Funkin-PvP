package data.game;

import data.Controls.Action;

class InputManager
{
	public var autoplay:Bool;

	var ruleset:GameplayRuleset;
	var player:Int;
	var controls:Controls;
	var bindingStore:Array<InputBinding>;

	public function new(ruleset:GameplayRuleset, player:Int, autoplay:Bool = false)
	{
		this.ruleset = ruleset;
		this.player = player;
		this.autoplay = autoplay;
		controls = PlayerSettings.players[player].controls;

		setInputBinds();
	}

	public function handleInput(elapsed:Float)
	{
		for (lane in 0...bindingStore.length)
		{
			var needsUpdating = false;
			var bind = bindingStore[lane];

			if (!bind.pressed && controls.checkByName(bind.justPressedAction))
			{
				bind.pressed = true;
				needsUpdating = true;
			}
			else if (bind.pressed && controls.checkByName(bind.justReleasedAction))
			{
				bind.pressed = false;
				needsUpdating = true;
			}

			if (!needsUpdating)
				continue;

			var manager = ruleset.noteManagers[player];
			if (bind.pressed)
			{
				var note = manager.getClosestTap(lane);
			}
		}
	}

	function setInputBinds()
	{
		bindingStore = [
			new InputBinding(NOTE_LEFT_P, NOTE_LEFT, NOTE_LEFT_R),
			new InputBinding(NOTE_DOWN_P, NOTE_DOWN, NOTE_DOWN_R),
			new InputBinding(NOTE_UP_P, NOTE_UP, NOTE_UP_R),
			new InputBinding(NOTE_RIGHT_P, NOTE_RIGHT, NOTE_RIGHT_R)
		];
	}
}

class InputBinding
{
	public var justPressedAction:Action;
	public var pressedAction:Action;
	public var justReleasedAction:Action;
	public var pressed:Bool;

	public function new(justPressedAction:Action, pressedAction:Action, justReleasedAction:Action)
	{
		this.justPressedAction = justPressedAction;
		this.pressedAction = pressedAction;
		this.justReleasedAction = justReleasedAction;
	}
}
