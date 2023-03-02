package ui;

import data.Settings;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;
import ui.MenuList;

using StringTools;

class SettingsMenuList extends TypedMenuList<SettingsMenuItem>
{
	public function createItem(data:SettingData, ?callback:Void->Void)
	{
		var item = new SettingsMenuItem(0, length * 120, data.displayName, callback, data);
		return addItem(item.name, item);
	}
}

class SettingsMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var data:SettingData;
	public var nameText:FlxText;
	public var checkbox:Checkbox;
	public var valueText:FlxText;
	public var value(get, set):Dynamic;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, data:SettingData)
	{
		this.data = resolveSettingData(data);

		var label = new FlxSpriteGroup();
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
		}
	}

	function updateValueText()
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
		if (data.changeAmount == null)
			data.changeAmount = 0.1;
		if (data.scrollDelay == null)
			data.scrollDelay = 0.1;
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
	var name:String;
	var displayName:String;
	var description:String;
	var type:SettingType;
	var defaultValue:Dynamic;
	var ?displayFormat:String;
	var ?minValue:Float;
	var ?maxValue:Float;
	var ?changeAmount:Float;
	var ?scrollDelay:Float;
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
