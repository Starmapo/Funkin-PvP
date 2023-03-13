package states.options;

import ui.lists.TextMenuList;

class OptionsPage extends Page
{
	static var lastSelected:Int = 0;

	var items:TextMenuList;

	public function new()
	{
		super();

		items = new TextMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		createItem('Players', switchPage.bind(Players));
		createItem('Video', switchPage.bind(Video));
		createItem('Audio', switchPage.bind(Audio));
		// createItem('Gameplay', switchPage.bind(Gameplay));
		createItem('Miscellaneous', switchPage.bind(Miscellaneous));
		createItem('Exit', exit);

		items.selectItem(lastSelected);
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
		camFollow.setPosition(midpoint.x, midpoint.y);
		midpoint.put();
	}

	function onChange(item:TextMenuItem)
	{
		updateCamFollow(item);
		lastSelected = item.ID;
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
