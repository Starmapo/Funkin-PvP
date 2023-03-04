package states.options;

import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.SettingsMenuList;

class BaseSettingsPage extends Page
{
	var items:SettingsMenuList;
	var descBG:FlxSprite;
	var descText:FlxText;
	var descTween:FlxTween;

	public function new()
	{
		super();

		descBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBG.scrollFactor.set();
		descBG.alpha = 0.8;

		descText = new FlxText(0, 0, FlxG.width - 10);
		descText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();

		items = new SettingsMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		add(descBG);
		add(descText);
	}

	override function onAppear()
	{
		updateCamFollow(items.selectedItem);
		updateDesc(items.selectedItem, false);
	}

	override function exit()
	{
		Settings.saveData();
		super.exit();
	}

	function addSetting(data:SettingData, ?callback:Void->Void)
	{
		var item = new SettingsMenuItem(0, items.length * 140, data.displayName, callback, data);
		return items.addItem(item.name, item);
	}

	function updateCamFollow(item:SettingsMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.setPosition(FlxG.width / 2, midpoint.y);
		midpoint.put();
	}

	function onChange(item:SettingsMenuItem)
	{
		updateCamFollow(item);
		updateDesc(item, true);
	}

	function onAccept(item:SettingsMenuItem) {}

	function updateDesc(item:SettingsMenuItem, tween:Bool = false)
	{
		descText.text = item.data.description;
		descText.screenCenter(X);
		descText.y = FlxG.height - descText.height - 10;
		descBG.setGraphicSize(Std.int(descText.width + 4), Std.int(descText.height + 4));
		descBG.updateHitbox();
		descBG.setPosition(descText.x - 2, descText.y - 2);

		if (tween)
			tweenDesc();
	}

	function tweenDesc()
	{
		if (descTween != null)
			descTween.cancel();

		descText.y -= 10;
		descBG.y = descText.y;
		descTween = FlxTween.tween(descText, {y: descText.y + 10}, 0.2, {
			onUpdate: function(_)
			{
				descBG.y = descText.y;
			},
			onComplete: function(_)
			{
				descTween = null;
			}
		});
	}

	override function set_controlsEnabled(value:Bool)
	{
		items.controlsEnabled = value;
		return super.set_controlsEnabled(value);
	}
}
