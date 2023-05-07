package ui.lists;

import data.Settings;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import sprites.AnimatedSprite;
import ui.lists.MenuList;

using StringTools;

typedef SettingsMenuList = TypedSettingsMenuList<SettingsMenuItem>;

class TypedSettingsMenuList<T:SettingsMenuItem> extends TypedMenuList<T>
{
	var itemHoldTime:Float = 0;
	var itemLastHoldTime:Float = 0;

	override function updateControls()
	{
		super.updateControls();

		if (selectedItem != null)
		{
			if (!selectedItem.canAccept)
			{
				if (navigateItem(selectedItem, checkAction(UI_LEFT_P), checkAction(UI_RIGHT_P), checkAction(UI_LEFT), checkAction(UI_RIGHT)))
				{
					if (selectedItem.callback != null)
						selectedItem.callback();

					if (playScrollSound)
						CoolUtil.playScrollSound();
				}
			}

			if (checkAction(RESET_P) && selectedItem.data.type != ACTION && selectedItem.value != selectedItem.data.defaultValue)
			{
				selectedItem.value = selectedItem.data.defaultValue;

				if (selectedItem.callback != null)
					selectedItem.callback();

				if (playScrollSound)
					CoolUtil.playScrollSound();
			}
		}
	}

	override function accept()
	{
		onAccept.dispatch(selectedItem);

		if (selectedItem != null && selectedItem.data.type == CHECKBOX)
		{
			selectedItem.value = !selectedItem.value;

			if (playScrollSound)
				CoolUtil.playScrollSound();
		}

		if (fireCallbacks && selectedItem.callback != null && selectedItem.canAccept)
			selectedItem.callback();
	}

	function navigateItem(item:T, prev:Bool, next:Bool, prevHold:Bool, nextHold:Bool)
	{
		var canHold = holdEnabled && item.data.type != STRING;
		if (prev == next && (!canHold || prevHold == nextHold))
			return false;

		var lastValue = item.value;

		if (prev || next)
		{
			itemHoldTime = itemLastHoldTime = 0;
			changeItemValue(item, prev);

			return item.value != lastValue;
		}
		else if (canHold && (prevHold || nextHold))
		{
			itemHoldTime += FlxG.elapsed;

			if (itemHoldTime >= minScrollTime && itemHoldTime - itemLastHoldTime >= item.data.holdDelay)
			{
				changeItemValue(item, prevHold, item.data.holdMult);
				itemLastHoldTime = itemHoldTime;
			}

			return item.value != lastValue;
		}

		return false;
	}

	function changeItemValue(item:T, prev:Bool, mult:Float = 1)
	{
		var value:Dynamic = item.value;
		switch (item.data.type)
		{
			case NUMBER, PERCENT:
				if (prev)
					value -= item.data.changeAmount * mult;
				else
					value += item.data.changeAmount * mult;
				value = FlxMath.roundDecimal(value, item.data.decimals);
				if (item.data.wrap && item.data.minValue != null && item.data.maxValue != null)
				{
					value = FlxMath.wrap(value, item.data.minValue, item.data.maxValue);
				}
				else
				{
					value = FlxMath.bound(value, item.data.minValue, item.data.maxValue);
				}
			case STRING:
				if (item.data.options == null || item.data.options.length <= 1)
					return;

				var index = item.data.options.indexOf(value);
				if (index < 0)
					index = 0;
				if (prev)
					index -= 1;
				else
					index += 1;
				if (item.data.wrap)
				{
					index = FlxMath.wrapInt(index, 0, item.data.options.length - 1);
				}
				else
				{
					index = FlxMath.boundInt(index, 0, item.data.options.length - 1);
				}
				value = item.data.options[index];
			default:
		}
		item.value = value;
	}
}

class SettingsMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var data:SettingData;
	// public var nameBG:FlxUI9SliceSprite;
	public var nameText:FlxText;
	public var checkbox:Checkbox;
	public var valueText:FlxText;
	public var value(get, set):Dynamic;
	public var canAccept(get, never):Bool;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, data:SettingData)
	{
		this.data = resolveSettingData(data);

		var label = new FlxSpriteGroup();

		/*
			nameBG = new FlxUI9SliceSprite(2, 0, Paths.getImage('menus/9SliceBlack'), new Rectangle(0, 0, 18, 18));
			nameBG.alpha = 0.2;
			label.add(nameBG);
		 */

		nameText = new FlxText(5, 0, 0, '', 65);
		nameText.setFormat('PhantomMuff 1.5', nameText.size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		label.add(nameText);

		super(x, y, label, name, callback);

		setEmptyBackground();
		setData(name, callback);
	}

	override function setData(name:String, ?callback:Void->Void)
	{
		super.setData(name, callback);

		if (label != null)
		{
			if (checkbox != null)
			{
				label.remove(checkbox);
				checkbox = FlxDestroyUtil.destroy(checkbox);
			}
			if (valueText != null)
			{
				label.remove(valueText);
				valueText = FlxDestroyUtil.destroy(valueText);
			}

			nameText.text = data.displayName;
			nameText.size = 65;
			var maxWidth = (FlxG.width / 2) - 10;
			switch (data.type)
			{
				case CHECKBOX:
					checkbox = new Checkbox(FlxG.width / 2 + ((FlxG.width / 2 - 102) / 2), 0, value);
					label.add(checkbox);
				case ACTION:
					maxWidth = FlxG.width - 10;
					nameText.screenCenter(X);
					nameText.x += x;
				default:
					valueText = new FlxText((FlxG.width / 2) + 5, 0, 0, '', 65);
					valueText.setFormat('PhantomMuff 1.5', valueText.size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
					updateValueText();
					label.add(valueText);
			}
			if (nameText.width > maxWidth)
			{
				var ratio = maxWidth / nameText.width;
				nameText.size = Math.floor(nameText.size * ratio);
			}
			/*
				nameBG.x = nameText.x - 2;
				nameBG.y = nameText.y - 2;
				nameBG.resize(nameText.width + 4, nameText.height + 4);
			 */
		}
	}

	public function updateValueText()
	{
		if (valueText == null)
			return;

		var displayText = Std.string(data.displayFunction(value));
		valueText.text = '< ' + displayText + ' >';

		valueText.size = 65;
		var maxWidth = (FlxG.width / 2) - 10;
		if (valueText.width > maxWidth)
		{
			var ratio = (maxWidth / valueText.width);
			valueText.size = Math.floor(valueText.size * ratio);
		}
		valueText.x = (FlxG.width / 2) + 5 + ((maxWidth - valueText.width) / 2);
	}

	function resolveSettingData(data:SettingData)
	{
		if (data.displayFunction == null)
		{
			data.displayFunction = switch (data.type)
			{
				case PERCENT:
					function(value)
					{
						var value:Float = value;
						return (value * 100) + '%';
					};
				default:
					function(value)
					{
						return value;
					};
			}
		}

		if (data.decimals == null)
			data.decimals = (data.type == PERCENT ? 2 : 0);

		if (data.changeAmount == null)
			data.changeAmount = (data.decimals > 0 ? 0.1 : 1);

		if (data.holdDelay == null)
			data.holdDelay = (data.type == PERCENT ? 0.05 : 0);

		if (data.holdMult == null)
			data.holdMult = 1;

		if (data.wrap == null)
			data.wrap = (data.type == STRING);

		return data;
	}

	function get_value():Dynamic
	{
		return Reflect.getProperty(Settings, data.name);
	}

	function set_value(value:Dynamic):Dynamic
	{
		Reflect.setProperty(Settings, data.name, value);
		switch (data.type)
		{
			case CHECKBOX:
				checkbox.value = value;
			case ACTION:
			default:
				updateValueText();
		}
		return value;
	}

	function get_canAccept()
	{
		return data.type == CHECKBOX || data.type == ACTION;
	}
}

class Checkbox extends AnimatedSprite
{
	public var value(default, set):Bool;

	public function new(x:Float = 0, y:Float = 0, value:Bool = false)
	{
		super(x, y, Paths.getSpritesheet('menus/options/checkboxThingie'), 0.7);

		addAnim({
			name: 'static',
			atlasName: 'Check Box unselected',
			loop: false
		}, true);
		addAnim({
			name: 'checked',
			atlasName: 'Check Box selecting animation',
			loop: false,
			offset: [17, 70]
		});

		this.value = value;
		animation.finish();
		antialiasing = true;
	}

	function set_value(newValue:Bool)
	{
		if (value != newValue)
		{
			if (newValue)
				playAnim('checked');
			else
				playAnim('static');
		}

		return value = newValue;
	}
}

typedef SettingData =
{
	var ?name:String;
	var displayName:String;
	var description:String;
	var type:SettingType;
	var ?defaultValue:Dynamic;
	var ?displayFunction:Dynamic->Dynamic;
	var ?minValue:Float;
	var ?maxValue:Float;
	var ?decimals:Int;
	var ?changeAmount:Float;
	var ?holdDelay:Float;
	var ?holdMult:Float;
	var ?wrap:Bool;
	var ?options:Array<String>;
}

enum SettingType
{
	CHECKBOX;
	NUMBER;
	PERCENT;
	STRING;
	ACTION;
}
