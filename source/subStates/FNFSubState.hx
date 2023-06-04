package subStates;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class FNFSubState extends FlxSubState
{
	public var dropdowns:Array<FlxUIDropDownMenu> = [];

	var checkDropdowns:Bool = false;

	public function new()
	{
		super();
		memberAdded.add(onMemberAdded);
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
}
