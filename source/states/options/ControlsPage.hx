package states.options;

import components.ActionBinds;
import flixel.FlxG;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.components.SectionHeader;
import haxe.ui.containers.Box;
import haxe.ui.core.Screen;

using StringTools;

class ControlsPage extends Page
{
	public var player:Int;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		rpcDetails = 'Player ${player + 1} Controls';
		
		add(new ControlsView(player));
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}

class ControlsView extends Box
{
	public function new(player:Int)
	{
		super();
		width = Screen.instance.width;
		height = Screen.instance.height;
		
		final ui = RuntimeComponentBuilder.fromAsset("assets/data/ui/views/controls.xml");
		for (c in ui.findComponents(null, ActionBinds))
			c.player = player;
			
		// add note controls
		final scrollView = ui.findComponent("scrollView");
		for (i in 1...Main.MAX_KEY_AMOUNT + 1)
		{
			final header = new SectionHeader();
			header.text = i + 'K';
			scrollView.addComponent(header);
			
			for (key in 1...i + 1)
			{
				final binds = new ActionBinds();
				binds.setAction(NOTE(i, key));
				binds.player = player;
				scrollView.addComponent(binds);
			}
		}

		addComponent(ui);
	}
}
