package states;

import flixel.FlxG;

class TestState extends FNFState
{
	override function create()
	{
		FlxG.camera.bgColor = 0;
		
		add(new states.options.ControlsPage.ControlsView(0));
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}
