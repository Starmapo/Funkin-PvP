package states.options;

import backend.util.HaxeUIUtil;
import flixel.FlxG;
import haxe.ui.RuntimeComponentBuilder;

class ControlsPage extends Page
{
	public var player:Int;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		
		HaxeUIUtil.initToolkit();
		
		var view = RuntimeComponentBuilder.fromAsset("assets/data/ui/controls.xml");
		add(view);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}
