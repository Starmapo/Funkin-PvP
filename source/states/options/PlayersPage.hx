package states.options;

import objects.menus.lists.TextMenuList;

class PlayersPage extends Page
{
	var items:TextMenuList;
	
	public function new()
	{
		super();
		rpcDetails = 'Player Options';
		
		items = new TextMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);
		
		createItem('Player 1', switchPage.bind(Player(0)));
		createItem('Player 2', switchPage.bind(Player(1)));
		
		addPageTitle('Players');
	}
	
	override function destroy()
	{
		super.destroy();
		items = null;
	}
	
	override function onAppear()
	{
		updateCamFollow(items.selectedItem);
	}
	
	function createItem(name:String, ?callback:Void->Void)
	{
		var item = new TextMenuItem(0, items.length * 100, name, callback);
		item.screenCenter(X);
		return items.addItem(name, item);
	}
	
	function updateCamFollow(item:TextMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
	
	function onChange(item:TextMenuItem)
	{
		updateCamFollow(item);
	}
	
	function onAccept(item:TextMenuItem)
	{
		CoolUtil.playConfirmSound();
	}
	
	override function set_controlsEnabled(value:Bool)
	{
		items.controlsEnabled = value;
		return super.set_controlsEnabled(value);
	}
}
