package ui;

import data.Settings;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;
import ui.MenuList;

using StringTools;

typedef SettingsMenuList = TypedSettingsMenuList<SettingsMenuItem>;

class TypedSettingsMenuList<T:SettingsMenuItem> extends TypedMenuList<T>
{
	var itemHoldTime:Float = 0;
	var itemLastHoldTime:Float = 0;

	override function updateControls()
	{
		super.updateControls();

		if (selectedItem != null && selectedItem.isScroll)
		{
			if (navigateItem(selectedItem, checkAction(UI_LEFT_P), checkAction(UI_RIGHT_P), checkAction(UI_LEFT), checkAction(UI_RIGHT)))
			{
				if (selectedItem.callback != null)
					selectedItem.callback();

				if (playScrollSound)
					CoolUtil.playScrollSound();
			}
		}
	}

	override function accept()
	{
		super.accept();

		if (selectedItem != null && selectedItem.data.type == CHECKBOX)
		{
			selectedItem.value = !selectedItem.value;

			if (playScrollSound)
				CoolUtil.playScrollSound();
		}
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
		var value:Float = item.value;
		if (prev)
			value -= item.data.changeAmount * mult;
		else
			value += item.data.changeAmount * mult;
		value = FlxMath.bound(FlxMath.roundDecimal(value, item.data.decimals), item.data.minValue, item.data.maxValue);
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
	public var isScroll(get, never):Bool;

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
				checkbox.destroy();
				checkbox = null;
			}
			if (valueText != null)
			{
				label.remove(valueText);
				valueText.destroy();
				valueText = null;
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

		var displayValue = Std.string(data.type == PERCENT ? (value * 100) : value);
		var displayText = data.displayFormat.replace('%v', displayValue);
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
		if (data.displayFormat == null)
		{
			data.displayFormat = switch (data.type)
			{
				case PERCENT:
					'%v%';
				default:
					'%v';
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

		return data;
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

	override function set_alpha(value:Float):Float
	{
		super.set_alpha(value);
		// nameBG.alpha = 0.8;
		return alpha;
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

	function get_isScroll()
	{
		return data.type != CHECKBOX && data.type != ACTION;
	}
}

class Checkbox extends AnimatedSprite
{
	public var value(default, set):Bool;

	public function new(x:Float = 0, y:Float = 0, value:Bool = false)
	{
		super(x, y, Paths.getSpritesheet('menus/options/checkboxThingie'));

		addAnim({
			name: 'static',
			atlasName: 'Check Box unselected',
			loop: false,
			offset: [0, 0]
		});
		addAnim({
			name: 'checked',
			atlasName: 'Check Box selecting animation',
			loop: false,
			offset: [17, 70]
		});

		scale.set(0.7, 0.7);
		updateHitbox();

		playAnim('static');

		this.value = value;
		animation.finish();
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
	var ?displayFormat:String;
	var ?minValue:Float;
	var ?maxValue:Float;
	var ?decimals:Int;
	var ?changeAmount:Float;
	var ?holdDelay:Float;
	var ?holdMult:Float;
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
