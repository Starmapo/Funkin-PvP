package states.options;

import backend.util.HaxeUIUtil;
import components.ActionBinds;
import flixel.FlxG;
import haxe.ui.containers.VBox;

using StringTools;

class ControlsPage extends Page
{
	public var player:Int;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		rpcDetails = 'Player ${player + 1} Controls';
		
		HaxeUIUtil.addView(this, new ControlsView(player));
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}

@:build(haxe.ui.ComponentBuilder.build("assets/data/ui/views/controls.xml"))
class ControlsView extends VBox
{
	public function new(player:Int)
	{
		super();
		
		for (c in findComponents(null, ActionBinds))
			c.player = player;
	}
}
