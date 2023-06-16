package states.options;

import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.lists.SettingsMenuList;

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
		rpcDetails = 'Player ${player + 1} Options';

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
			displayName: 'Change Controls',
			description: 'Change your device and key/button binds.',
			type: ACTION
		}, switchPage.bind(Controls(player)));
		addSetting({
			displayName: 'Change Note Skin',
			description: 'Change your note skin.',
			type: ACTION
		}, switchPage.bind(NoteSkin(player)));
		addSetting({
			displayName: 'Change Judgement Skin',
			description: 'Change your judgement skin.',
			type: ACTION
		}, switchPage.bind(JudgementSkin(player)));
		addSetting({
			displayName: 'Change Splash Skin',
			description: 'Change your note splash skin.',
			type: ACTION
		}, switchPage.bind(SplashSkin(player)));
		addSetting({
			name: 'downScroll',
			displayName: 'Down Scroll',
			description: 'If enabled, the notes will go down instead of up.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'notesScale',
			displayName: 'Note Scale',
			description: 'Change how big the notes and receptors should be.',
			type: NUMBER,
			defaultValue: 1,
			displayFunction: function(v)
			{
				return v + 'x';
			},
			minValue: 0.5,
			maxValue: 1,
			decimals: 2,
			changeAmount: 0.05
		});
		addSetting({
			name: 'scrollSpeed',
			displayName: 'Scroll Speed',
			description: 'Change how fast the notes should be going.',
			type: NUMBER,
			defaultValue: 1,
			displayFunction: function(v)
			{
				return v + 'x';
			},
			minValue: 0.25,
			maxValue: 5,
			decimals: 2,
			changeAmount: 0.01
		});
		addSetting({
			name: 'judgementCounter',
			displayName: 'Judgement Counter',
			description: 'If enabled, a counter will keep track of your current judgements.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'npsDisplay',
			displayName: 'NPS Display',
			description: 'If enabled, your current notes per second are visible.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'msDisplay',
			displayName: 'Hit MS Display',
			description: 'If enabled, shows the millisecond difference when you hit a note.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'transparentReceptors',
			displayName: 'Transparent Receptors',
			description: 'If enabled, the receptors will be see-through.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'transparentHolds',
			displayName: 'Transparent Holds',
			description: 'If enabled, note holds will be see-through.',
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'noteSplashes',
			displayName: 'Note Splashes',
			description: 'If enabled, a splash will appear when you get a "Sick" or "Marvelous" judgement.',
			type: CHECKBOX,
			defaultValue: true
		});
		addSetting({
			name: 'noReset',
			displayName: 'Disable Reset Button',
			description: "If enabled, pressing RESET won't kill you.",
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'autoplay',
			displayName: 'Autoplay',
			description: "Whether to let the game play this player's side.",
			type: CHECKBOX,
			defaultValue: false
		});

		addPageTitle('Player ${player + 1}');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		descBG.y = descText.y - 2;
	}

	override function destroy()
	{
		super.destroy();
		items = null;
		descBG = null;
		descText = null;
		descTween = null;
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
		camFollow.y = midpoint.y;
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
		descBG.setGraphicSize(descText.width + 4, descText.height + 4);
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

	override function getDefaultValue()
	{
		return data.defaultValue;
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
