package states.options;

import components.ActionBinds;
import flixel.FlxG;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.components.DropDown;
import haxe.ui.components.SectionHeader;
import haxe.ui.containers.Box;
import haxe.ui.core.Screen;

using StringTools;

class ControlsPage extends Page
{
	public var player:Int;
	
	var view:ControlsView;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		rpcDetails = 'Player ${player + 1} Controls';
		
		add(view = new ControlsView(player));
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
	
	override function destroy()
	{
		view = null;
		super.destroy();
	}
	
	override function onAppear()
	{
		view.disabled = false;
		super.onAppear();
	}
	
	override function exit()
	{
		view.disabled = true;
		super.exit();
	}
}

class ControlsView extends Box
{
	var deviceDropdown:DropDown;
	
	public function new(player:Int)
	{
		super();
		width = Screen.instance.width;
		height = Screen.instance.height;
		
		final ui = RuntimeComponentBuilder.fromAsset("assets/data/ui/views/controls.xml");
		deviceDropdown = ui.findComponent("deviceDropdown");
		
		// prevent player 1 from having no controls
		if (player == 0)
			deviceDropdown.dataSource.removeAt(0);
			
		for (c in ui.findComponents(null, ActionBinds))
			c.player = player;
			
		// add note controls
		final scrollView = ui.findComponent("scrollView");
		for (keys in 1...Main.MAX_KEY_AMOUNT + 1)
		{
			final header = new SectionHeader();
			header.text = keys + 'K';
			scrollView.addComponent(header);
			
			for (key in 0...keys)
			{
				final binds = new ActionBinds();
				binds.setAction(NOTE(keys, key));
				binds.player = player;
				scrollView.addComponent(binds);
			}
		}
		
		addComponent(ui);
	}
	
	public function onExit()
	{
		deviceDropdown.focus = false;
		deviceDropdown.hideDropDown();
		disabled = true;
	}
	
	override function destroy()
	{
		deviceDropdown = null;
		super.destroy();
	}
}
