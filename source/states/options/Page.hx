package states.options;

import data.PlayerSettings;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;

class Page extends FlxGroup
{
	public var controlsEnabled(default, set):Bool = true;
	public var onSwitch(default, null) = new FlxTypedSignal<PageName->Void>();
	public var onExit(default, null) = new FlxSignal();
	public var onOpenSubState(default, null) = new FlxTypedSignal<FlxSubState->Void>();

	var camFollow(get, never):FlxObject;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		if (controlsEnabled)
			updateControls();

		super.update(elapsed);
	}

	public function onAppear() {}

	function updateControls()
	{
		if (PlayerSettings.checkAction(BACK_P))
		{
			CoolUtil.playCancelSound();
			exit();
		}
	}

	function exit()
	{
		onExit.dispatch();
	}

	function switchPage(name:PageName)
	{
		onSwitch.dispatch(name);
	}

	function openSubState(subState:FlxSubState)
	{
		onOpenSubState.dispatch(subState);
	}

	function get_camFollow()
	{
		return OptionsState.camFollow;
	}

	function set_controlsEnabled(value:Bool)
	{
		return controlsEnabled = value;
	}
}
