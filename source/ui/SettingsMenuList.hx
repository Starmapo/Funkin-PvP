package ui;

import data.Settings;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;
import ui.MenuList;

class SettingsMenuList extends TypedMenuList<SettingsMenuItem>
{
	public function createItem(name:String, ?callback:Void->Void, data:SettingData)
	{
		var item = new SettingsMenuItem(0, length * 120, name, callback, data);
		return addItem(name, item);
	}
}

class SettingsMenuItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var data:SettingData;
	public var nameText:FlxText;
	public var checkbox:Checkbox;
	public var valueText:FlxText;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, data:SettingData)
	{
		this.data = data;
		var label = new FlxSpriteGroup();
		nameText = new FlxText(0, 0, 0, '', 65);
		nameText.setFormat('PhantomMuff 1.5', nameText.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		label.add(nameText);

		super(x, y, label, name, callback);
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
			var value = Reflect.getProperty(Settings, data.name);
			var maxWidth = (FlxG.width / 2) - 10;
			switch (data.type)
			{
				case CHECKBOX:
					var pos = FlxG.width - 140;
					nameText.x = x + 5;
					maxWidth = pos - 10;

					checkbox = new Checkbox(pos, 0, value);
					label.add(checkbox);
				case ACTION:
					maxWidth = FlxG.width - 10;
					nameText.screenCenter(X);
					nameText.x += x;
				default:
					nameText.x = x + 5;

					valueText = new FlxText((FlxG.width / 2) + 5, 0, 0, '', 65);
					valueText.setFormat('PhantomMuff 1.5', valueText.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
					updateValue(value);
					label.add(valueText);
			}
			if (nameText.width > maxWidth)
			{
				var ratio = maxWidth / nameText.width;
				nameText.size = Math.floor(nameText.size * ratio);
			}
		}
	}

	function updateValue(value:Dynamic)
	{
		if (valueText == null)
			return;

		if (data.type == PERCENT)
		{
			var num:Float = value * 100;
			valueText.text = '< ' + num + '% >';
		}
		else
			valueText.text = '< ' + value + ' >';

		valueText.size = 65;
		var maxWidth = (FlxG.width / 2) - 10;
		if (valueText.width > maxWidth)
		{
			var ratio = (maxWidth / valueText.width);
			valueText.size = Math.floor(valueText.size * ratio);
		}
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

class Checkbox extends AnimatedSprite
{
	var value(default, set):Bool;

	public function new(x:Float = 0, y:Float = 0, value:Bool = false)
	{
		super(x, y, Paths.getSpritesheet('menus/options/checkboxThingie'));

		addAnim({
			name: 'static',
			atlasName: 'Check Box unselected',
			loop: false
		});
		addAnim({
			name: 'checked',
			atlasName: 'Check Box selecting animation',
			loop: false,
			offset: [17, 70]
		});
		playAnim('static');

		scale.set(0.7, 0.7);
		updateHitbox();

		this.value = value;
	}

	function set_value(newValue:Bool)
	{
		if (newValue)
			playAnim('checked', true);
		else
			playAnim('static');

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
	var ?options:Array<String>;
	var ?enumClass:Dynamic;
}

enum SettingType
{
	CHECKBOX;
	INTEGER;
	FLOAT;
	PERCENT;
	STRING;
	ENUM;
	ACTION;
}
