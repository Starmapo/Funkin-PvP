package states.options;

import data.PlayerSettings;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;

class Page extends FlxGroup
{
	public var controlsEnabled(default, set):Bool = true;
	public var onSwitch(default, null):FlxTypedSignal<PageName->Void> = new FlxTypedSignal();
	public var onExit(default, null) = new FlxSignal();
	public var onOpenSubState(default, null):FlxTypedSignal<FlxSubState->Void> = new FlxTypedSignal();
	public var rpcDetails:String = '';
	
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
	
	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(onSwitch);
		FlxDestroyUtil.destroy(onExit);
		FlxDestroyUtil.destroy(onOpenSubState);
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
	
	function addPageTitle(text:String)
	{
		var title = new FlxText(5, 5, 0, text);
		title.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		title.alpha = 0.6;
		add(title);
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
