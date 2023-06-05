package subStates;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;

class FNFSubState extends FlxSubState
{
	public var dropdowns:Array<FlxUIDropDownMenu> = [];

	var checkDropdowns:Bool = false;
	var camSubState:FlxCamera;

	public function new()
	{
		super();
		memberAdded.add(onMemberAdded);
		openCallback = onOpen;
		closeCallback = onClose;
	}

	public function checkAllowInput()
	{
		if (FlxG.stage.focus != null)
			return false;

		for (dropdown in dropdowns)
		{
			if (dropdown.dropPanel.exists)
				return false;
		}

		return true;
	}

	override function destroy()
	{
		super.destroy();
		if (camSubState != null && FlxG.cameras.list.contains(camSubState))
			FlxG.cameras.remove(camSubState);
		camSubState = null;
	}

	function onOpen()
	{
		if (camSubState != null)
			camSubState.visible = true;
	}

	function onClose()
	{
		if (camSubState != null)
			camSubState.visible = false;
	}

	function onMemberAdded(obj:FlxBasic)
	{
		if (checkDropdowns)
			checkDropdown(obj);
	}

	function checkDropdown(obj:FlxBasic)
	{
		if (Std.isOfType(obj, FlxUIDropDownMenu))
		{
			var dropdown:FlxUIDropDownMenu = cast obj;
			dropdowns.push(dropdown);
		}
		else if (Std.isOfType(obj, FlxTypedGroup))
		{
			var group:FlxTypedGroup<Dynamic> = cast obj;
			for (obj in group)
				checkDropdown(obj);
		}
		else if (Std.isOfType(obj, FlxTypedSpriteGroup))
		{
			var group:FlxTypedSpriteGroup<Dynamic> = cast obj;
			for (obj in group.group)
				checkDropdown(obj);
		}
	}

	function createCamera(?bgColor:FlxColor)
	{
		if (camSubState != null)
			return;
		if (bgColor == null)
			bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.6);

		camSubState = new FlxCamera();
		camSubState.bgColor = bgColor;
		camSubState.visible = false;
		FlxG.cameras.add(camSubState, false);
		cameras = [camSubState];
	}
}
