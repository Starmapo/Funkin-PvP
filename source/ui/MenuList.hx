package ui;

import data.Controls.Action;
import data.PlayerSettings;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal.FlxTypedSignal;

class TypedMenuList<T:MenuItem> extends FlxTypedGroup<T>
{
	/**
		The current index.
	**/
	public var selectedIndex(default, null):Int = 0;

	/**
		The currently selected item.
	**/
	public var selectedItem(get, never):T;

	/**
		The navigation mode for this list.
	**/
	public var navMode:NavMode;

	/**
		The controls mode for this list.
	**/
	public var controlsMode:ControlsMode;

	/**
		Whether the index will wrap around when going out of bounds.
	**/
	public var wrapEnabled:Bool;

	/**
		Whether the controls are enabled.
	**/
	public var controlsEnabled:Bool = true;

	/**
		Whether the scroll sound will play when the menu is navigated.
	**/
	public var playScrollSound:Bool = true;

	/**
		Called when a new item is selected.
	**/
	public var onChange(default, null):FlxTypedSignal<T->Void> = new FlxTypedSignal();

	/**
		Called when the accept button is pressed.
	**/
	public var onAccept(default, null):FlxTypedSignal<T->Void> = new FlxTypedSignal();

	var byName:Map<String, T> = new Map();

	public function new(?navMode:NavMode = VERTICAL, ?controlsMode:ControlsMode = ALL, wrapEnabled:Bool = true)
	{
		super();
		this.navMode = navMode;
		this.controlsMode = controlsMode;
		this.wrapEnabled = wrapEnabled;

		Paths.getSound('menus/scrollMenu');
	}

	override function update(elapsed:Float)
	{
		if (controlsEnabled)
			updateControls();

		super.update(elapsed);
	}

	public function addItem(name:String, item:T):T
	{
		if (length == selectedIndex)
			item.select();

		byName[name] = item;
		return add(item);
	}

	public function resetItem(oldName:String, newName:String, ?callback:Void->Void):T
	{
		if (!byName.exists(oldName))
			throw "No item named " + oldName;

		var item = byName[oldName];
		byName.remove(oldName);
		byName[newName] = item;
		item.setItem(newName, callback);

		return item;
	}

	function updateControls()
	{
		var index = switch (navMode)
		{
			case HORIZONTAL: navigate(checkAction(UI_LEFT_P), checkAction(UI_RIGHT_P));
			case VERTICAL: navigate(checkAction(UI_UP_P), checkAction(UI_DOWN_P));
			case BOTH: navigate(checkAction(UI_LEFT_P) || checkAction(UI_UP_P), checkAction(UI_RIGHT_P) || checkAction(UI_DOWN_P));
		}

		if (index != selectedIndex)
		{
			selectItem(index);
			if (playScrollSound)
				CoolUtil.playScrollSound();
		}

		if (checkAction(ACCEPT_P))
			accept();
	}

	function checkAction(action:Action)
	{
		return switch (controlsMode)
		{
			case ALL:
				PlayerSettings.checkAction(action);
			case PLAYER(player):
				PlayerSettings.checkPlayerAction(player, action);
		}
	}

	function checkActions(actions:Array<Action>)
	{
		for (action in actions)
		{
			if (checkAction(action))
			{
				return true;
			}
		}
		return false;
	}

	function navigate(prev:Bool, next:Bool)
	{
		var index = selectedIndex;

		if (prev == next)
			return index;

		if (prev)
		{
			if (index > 0)
				index--;
			else if (wrapEnabled)
				index = length - 1;
		}
		else
		{
			if (index < length - 1)
				index++;
			else if (wrapEnabled)
				index = 0;
		}

		return index;
	}

	function selectItem(index:Int)
	{
		var prevItem = members[selectedIndex];
		prevItem.idle();
		prevItem.selected = false;

		selectedIndex = index;

		var curItem = members[selectedIndex];
		curItem.select();
		curItem.selected = true;

		onChange.dispatch(curItem);
	}

	function accept()
	{
		var selectedItem = members[selectedIndex];
		onAccept.dispatch(selectedItem);

		if (selectedItem.callback != null)
			selectedItem.callback();
	}

	override function destroy()
	{
		super.destroy();
		byName.clear();
		onChange.removeAll();
		onAccept.removeAll();
	}

	inline function get_selectedItem():T
	{
		return members[selectedIndex];
	}
}

class MenuItem extends FlxSprite
{
	public var name(default, null):String;
	public var callback(default, null):Void->Void;
	public var selected:Bool = false;

	public function new(x:Float = 0, y:Float = 0, name:String, callback:Void->Void)
	{
		super(x, y, graphic);
	}

	function setData(name:String, ?callback:Void->Void)
	{
		this.name = name;

		if (callback != null)
			this.callback = callback;
	}

	public function setItem(name:String, ?callback:Void->Void)
	{
		setData(name, callback);

		if (selected)
			select();
		else
			idle();
	}

	public function idle()
	{
		alpha = 0.6;
	}

	public function select()
	{
		alpha = 1;
	}
}

enum NavMode
{
	HORIZONTAL;
	VERTICAL;
	BOTH;
}

enum ControlsMode
{
	ALL;
	PLAYER(player:Int);
}
