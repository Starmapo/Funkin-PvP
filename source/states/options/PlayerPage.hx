package states.options;

import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.SettingsMenuList;

class PlayerPage extends Page
{
	var player:Int = 0;
	var items:PlayerSettingsMenuList;
	var descBG:FlxSprite;
	var descText:FlxText;
	var descTween:FlxTween;

	public function new(player:Int)
	{
		super();
		this.player = player;

		descBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBG.scrollFactor.set();
		descBG.alpha = 0.8;

		descText = new FlxText(0, 0, FlxG.width - 10);
		descText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();

		items = new PlayerSettingsMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		add(descBG);
		add(descText);

		addSetting({
			name: 'downScroll',
			displayName: 'Down Scroll',
			description: 'If enabled, the notes will go down instead of up.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			displayName: 'Change Controls',
			description: 'Change your device and key/button binds.',
			type: ACTION
		}, switchPage.bind(Controls(player)));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		descBG.y = descText.y - 2;
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
		var item = new PlayerSettingsMenuItem(0, items.length * 140, data.displayName, callback, data, player);
		return items.addItem(item.name, item);
	}

	function updateCamFollow(item:PlayerSettingsMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.setPosition(FlxG.width / 2, midpoint.y);
		midpoint.put();
	}

	function onChange(item:PlayerSettingsMenuItem)
	{
		updateCamFollow(item);
		updateDesc(item, true);
	}

	function onAccept(item:PlayerSettingsMenuItem)
	{
		if (item.data.type == ACTION)
			CoolUtil.playConfirmSound();
	}

	function updateDesc(item:PlayerSettingsMenuItem, tween:Bool = false)
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
		descBG.y = descText.y - 2;
		descTween = FlxTween.tween(descText, {y: descText.y + 10}, 0.2, {
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

class PlayerSettingsMenuList extends TypedSettingsMenuList<PlayerSettingsMenuItem> {}

class PlayerSettingsMenuItem extends SettingsMenuItem
{
	public var player:Int = 0;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, data:SettingData, player:Int)
	{
		this.player = player;
		super(x, y, name, callback, data);
	}

	override function get_value():Dynamic
	{
		return Reflect.getProperty(PlayerSettings.players[player].config, data.name);
	}

	override function set_value(value:Dynamic):Dynamic
	{
		Reflect.setProperty(PlayerSettings.players[player].config, data.name, value);
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
