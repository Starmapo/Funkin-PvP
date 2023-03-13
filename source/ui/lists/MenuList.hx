package ui.lists;

import data.Controls.Action;
import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxSignal.FlxTypedSignal;

typedef MenuList = TypedMenuList<MenuItem>;

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
		Whether to instantly fire the current item's callback when the player presses accept.
	**/
	public var fireCallbacks:Bool = true;

	/**
		Called when a new item is selected.
	**/
	public var onChange(default, null):FlxTypedSignal<T->Void> = new FlxTypedSignal();

	/**
		Called when the accept button is pressed.
	**/
	public var onAccept(default, null):FlxTypedSignal<T->Void> = new FlxTypedSignal();

	/**
		Whether holding a button to scroll automatically is enabled.
	**/
	public var holdEnabled:Bool = true;

	/**
		The time it takes to start scrolling after holding a button.
	**/
	public var minScrollTime:Float = 0.5;

	/**
		The time to wait before scrolling again while holding.
	**/
	public var scrollDelay:Float = 0.1;

	var byName:Map<String, T> = new Map();
	var holdTime:Float = 0;
	var lastHoldTime:Float = 0;

	public function new(?navMode:NavMode = VERTICAL, ?controlsMode:ControlsMode = ALL, wrapEnabled:Bool = true)
	{
		super();
		this.navMode = navMode;
		this.controlsMode = controlsMode;
		this.wrapEnabled = wrapEnabled;

		CoolUtil.playScrollSound(0);
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

		item.ID = length;
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

	public function selectItem(index:Int)
	{
		index = FlxMath.wrapInt(index, 0, length - 1);

		var prevItem = members[selectedIndex];
		if (prevItem != null)
		{
			prevItem.idle();
			prevItem.selected = false;
		}

		selectedIndex = index;

		var curItem = members[selectedIndex];
		if (curItem != null)
		{
			curItem.select();
			curItem.selected = true;
		}

		onChange.dispatch(curItem);
	}

	public function getItemByName(name:String)
	{
		return byName.get(name);
	}

	function updateControls()
	{
		if (length > 1)
		{
			var index = switch (navMode)
			{
				case HORIZONTAL: navigate(checkAction(UI_LEFT_P), checkAction(UI_RIGHT_P), checkAction(UI_LEFT), checkAction(UI_RIGHT));
				case VERTICAL: navigate(checkAction(UI_UP_P), checkAction(UI_DOWN_P), checkAction(UI_UP), checkAction(UI_DOWN));
				case BOTH: navigate(checkAction(UI_LEFT_P) || checkAction(UI_UP_P), checkAction(UI_RIGHT_P) || checkAction(UI_DOWN_P), checkAction(UI_LEFT) || checkAction(UI_UP), checkAction(UI_RIGHT)
						|| checkAction(UI_DOWN));
			}

			if (index != selectedIndex)
			{
				selectItem(index);
				if (playScrollSound)
					CoolUtil.playScrollSound();
			}
		}

		if (length > 0 && checkAction(ACCEPT_P))
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

	function navigate(prev:Bool, next:Bool, prevHold:Bool, nextHold:Bool)
	{
		var index = selectedIndex;

		if (prev == next && (!holdEnabled || prevHold == nextHold))
			return index;

		if (prev || next)
		{
			holdTime = lastHoldTime = 0;
			index = changeIndex(index, prev);
		}
		else if (holdEnabled && (prevHold || nextHold))
		{
			holdTime += FlxG.elapsed;

			if (holdTime >= minScrollTime && holdTime - lastHoldTime >= scrollDelay)
			{
				index = changeIndex(index, prevHold);
				lastHoldTime = holdTime;
			}
		}

		return index;
	}

	function changeIndex(index:Int, prev:Bool)
	{
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
	};

	function accept()
	{
		onAccept.dispatch(selectedItem);

		if (fireCallbacks && selectedItem.callback != null)
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

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void)
	{
		super(x, y, graphic);
		setData(name, callback);
		idle();
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

	function setData(name:String, ?callback:Void->Void)
	{
		this.name = name;

		if (callback != null)
			this.callback = callback;
	}
}

class TypedMenuItem<T:FlxSprite> extends MenuItem
{
	public var label(default, set):T;

	public function new(x:Float = 0, y:Float = 0, label:T, name:String, ?callback:Void->Void)
	{
		super(x, y, name, callback);
		// set label after super otherwise setters fuck up
		this.label = label;
	}

	/**
	 * Use this when you only want to show the label
	 */
	function setEmptyBackground()
	{
		makeGraphic(1, 1, 0x0);
	}

	function set_label(value:T)
	{
		if (value != null)
		{
			value.x = x;
			value.y = y;
			value.alpha = alpha;
		}
		return this.label = value;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (label != null)
			label.update(elapsed);
	}

	override function draw()
	{
		super.draw();
		if (label != null)
		{
			label.cameras = cameras;
			label.scrollFactor.copyFrom(scrollFactor);
			label.draw();
		}
	}

	override function set_x(value:Float):Float
	{
		super.set_x(value);

		if (label != null)
			label.x = x;

		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);

		if (label != null)
			label.y = y;

		return y;
	}

	override function set_alpha(value:Float):Float
	{
		super.set_alpha(value);

		if (label != null)
			label.alpha = alpha;

		return alpha;
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
