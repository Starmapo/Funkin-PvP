package states;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import ui.editors.EditorDropdownMenu;

class FNFState extends FlxTransitionableState
{
	public var dropdowns:Array<EditorDropdownMenu> = [];

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
			if (dropdown.dropPanel.visible)
				return false;
		}

		return true;
	}

	override function destroy()
	{
		super.destroy();
		dropdowns = null;
	}

	function onMemberAdded(object:FlxBasic) {}
}
