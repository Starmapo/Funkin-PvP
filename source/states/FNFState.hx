package states;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;

class FNFState extends FlxTransitionableState
{
	public function new()
	{
		super();
		memberAdded.add(onMemberAdded);
	}

	public function checkAllowInput()
	{
		if (FlxG.stage.focus != null)
			return false;

		return true;
	}

	function onMemberAdded(object:FlxBasic) {}
}
