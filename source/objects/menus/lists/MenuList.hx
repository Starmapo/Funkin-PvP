package objects.menus.lists;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.FlxInput.FlxInputState;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
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
			updateControls(elapsed);
			
		super.update(elapsed);
	}
	
	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(onChange);
		FlxDestroyUtil.destroy(onAccept);
		byName = null;
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
		index = FlxMath.wrap(index, 0, FlxMath.maxInt(length - 1, 0));
		
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
	
	public function hasItem(name:String)
	{
		return byName.exists(name);
	}
	
	function updateControls(elapsed:Float)
	{
		if (length > 1)
		{
			var index = switch (navMode)
			{
				case HORIZONTAL: navigate(elapsed, justPressed(UI_LEFT), justPressed(UI_RIGHT), pressed(UI_LEFT), pressed(UI_RIGHT));
				case VERTICAL: navigate(elapsed, justPressed(UI_UP), justPressed(UI_DOWN), pressed(UI_UP), pressed(UI_DOWN));
				case COLUMNS(n): navigateColumns(elapsed);
				case BOTH: navigate(elapsed, justPressed(UI_LEFT) || justPressed(UI_UP), justPressed(UI_RIGHT) || justPressed(UI_DOWN), pressed(UI_LEFT) || pressed(UI_UP), pressed(UI_RIGHT)
						|| pressed(UI_DOWN));
			}
			
			if (index != selectedIndex)
			{
				selectItem(index);
				if (playScrollSound)
					CoolUtil.playScrollSound();
			}
		}
		
		if (length > 0 && justPressed(ACCEPT))
			accept();
	}
	
	function justPressed(action:Action)
	{
		return checkStatus(action, JUST_PRESSED);
	}
	
	function pressed(action:Action)
	{
		return checkStatus(action, PRESSED);
	}
	
	function checkStatus(action:Action, state:FlxInputState)
	{
		return switch (controlsMode)
		{
			case ALL:
				Controls.anyCheckStatus(action, state);
			case PLAYER(player):
				Controls.playerCheckStatus(player, action, state);
		}
	}
	
	function navigate(elapsed:Float, prev:Bool, next:Bool, prevHold:Bool, nextHold:Bool)
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
			holdTime += elapsed;
			
			if (holdTime >= minScrollTime && holdTime - lastHoldTime >= scrollDelay)
			{
				index = changeIndex(index, prevHold);
				lastHoldTime = holdTime;
			}
		}
		
		return index;
	}
	
	function navigateGrid(elapsed:Float, prev:Bool, next:Bool, prevHold:Bool, nextHold:Bool, prevJump:Bool, nextJump:Bool, prevJumpHold:Bool,
			nextJumpHold:Bool)
	{
		var index = selectedIndex;
		
		if (prev == next && prevJump == nextJump && (!holdEnabled || (prevHold == nextHold && prevJumpHold == nextJumpHold)))
			return index;
			
		if (prev || next)
		{
			holdTime = lastHoldTime = 0;
			index = changeIndex(index, prev);
		}
		else if (holdEnabled && (prevHold || nextHold))
		{
			holdTime += elapsed;
			
			if (holdTime >= minScrollTime && holdTime - lastHoldTime >= scrollDelay)
			{
				index = changeIndex(index, prevHold);
				lastHoldTime = holdTime;
			}
		}
		
		var jumpAmount = switch (navMode)
		{
			case COLUMNS(n): n;
			default: 1;
		}
		if (length > jumpAmount)
		{
			if (prevJump || nextJump)
			{
				holdTime = lastHoldTime = 0;
				index = jumpIndex(index, prevJump, nextJump, jumpAmount);
			}
			else if (holdEnabled && (prevJumpHold || nextJumpHold))
			{
				holdTime += elapsed;
				
				if (holdTime >= minScrollTime && holdTime - lastHoldTime >= scrollDelay)
				{
					index = jumpIndex(index, prevJumpHold, nextJumpHold, jumpAmount);
					lastHoldTime = holdTime;
				}
			}
		}
		
		return index;
	}
	
	// im dumb so this jump code only works with 4 columns (only type i've used so far)
	function jumpIndex(index:Int, prev:Bool, next:Bool, amount:Int = 1)
	{
		var ogIndex = index;
		if (prev && index < amount)
		{
			while (index + amount < length)
				index += amount;
			if (index == ogIndex)
				index = length - 1;
		}
		else if (next && members[index + amount] == null)
		{
			while (index - amount >= 0)
				index -= amount;
			if (index == ogIndex)
				index = length - 1;
		}
		else
			index = changeIndex(index, prev, amount);
			
		return index;
	}
	
	function navigateColumns(elapsed:Float)
	{
		return navigateGrid(elapsed, justPressed(UI_LEFT), justPressed(UI_RIGHT), pressed(UI_LEFT), pressed(UI_RIGHT), justPressed(UI_UP),
			justPressed(UI_DOWN), pressed(UI_UP), pressed(UI_DOWN));
	}
	
	function changeIndex(index:Int, prev:Bool, amount:Int = 1)
	{
		if (prev)
		{
			if (wrapEnabled)
				index = FlxMath.wrap(index - amount, 0, length - 1);
			else
				index = FlxMath.maxInt(index - amount, 0);
		}
		else
		{
			if (wrapEnabled)
				index = FlxMath.wrap(index + amount, 0, length - 1);
			else
				index = FlxMath.minInt(index + amount, length - 1);
		}
		return index;
	}
	
	function accept()
	{
		onAccept.dispatch(selectedItem);
		
		if (fireCallbacks && selectedItem.callback != null)
			selectedItem.callback();
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
	
	override function destroy()
	{
		super.destroy();
		callback = null;
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
	
	override function destroy()
	{
		super.destroy();
		label = FlxDestroyUtil.destroy(label);
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
			if (Std.isOfType(value, FlxTypedSpriteGroup))
				cast(value, FlxTypedSpriteGroup<Dynamic>).directAlpha = true;
			value.alpha = alpha;
		}
		return label = value;
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
			label.cameras = _cameras;
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
	
	override function set_color(value:FlxColor):FlxColor
	{
		super.set_color(value);
		
		if (label != null)
			label.color = color;
			
		return color;
	}
	
	override function get_width()
	{
		if (label != null)
		{
			return label.width;
		}
		
		return width;
	}
	
	override function get_height()
	{
		if (label != null)
		{
			return label.height;
		}
		
		return height;
	}
}

enum NavMode
{
	HORIZONTAL;
	VERTICAL;
	BOTH;
	COLUMNS(n:Int);
}

enum ControlsMode
{
	ALL;
	PLAYER(player:Int);
}
