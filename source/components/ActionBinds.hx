package components;

import backend.InputFormatter;
import backend.settings.PlayerConfig;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;

using StringTools;

class ActionBinds extends HBox
{
	static function formatActionName(action:Action)
	{
		return switch (action)
		{
			case NOTE(_, key):
				'Key $key';
			default:
				final words = Type.enumConstructor(action).replace('_', ' ').split(' ');
				for (i in 0...words.length)
				{
					if (words[i] != 'UI')
						words[i] = words[i].charAt(0).toUpperCase() + words[i].substr(1).toLowerCase();
				}
				words.join(' ');
		}
	}
	
	public var label:Label;
	public var bind1:Button;
	public var bind2:Button;
	public var swap:Button;
	
	public var action(default, set):String = '';
	public var player(default, set):Int = 0;
	
	var enumAction:Action;
	var config(get, never):PlayerConfig;
	
	public function new()
	{
		super();
		
		percentWidth = 100;
		
		final ui = RuntimeComponentBuilder.fromAsset("assets/data/ui/components/action-binds.xml");
		label = ui.findComponent("label");
		bind1 = ui.findComponent("bind1");
		bind2 = ui.findComponent("bind2");
		swap = ui.findComponent("swap");
		addComponent(ui);
	}
	
	public function setAction(action:Action)
	{
		enumAction = action;
		updateLabel();
		updateBinds();
	}
	
	function updateAction()
	{
		var enumAction = Type.createEnum(Action, action);
		if (enumAction != null)
			setAction(enumAction);
	}
	
	function updateLabel()
	{
		label.text = formatActionName(enumAction);
	}
	
	function updateBinds()
	{
		if (enumAction == null)
			return;
			
		bind1.text = getBind(0);
		bind2.text = getBind(1);
	}
	
	function getBind(i:Int)
	{
		final binds = config.controls.get(enumAction);
		final bind = (binds != null ? binds[i] : null) ?? -1;
		return InputFormatter.format(bind, config.device);
	}
	
	function set_action(value:String)
	{
		if (action != value)
		{
			action = value;
			updateAction();
		}
		return value;
	}
	
	function set_player(value:Int)
	{
		if (player != value)
		{
			player = value;
			updateBinds();
		}
		return value;
	}
	
	function get_config()
	{
		return Settings.playerConfigs[player];
	}
}
