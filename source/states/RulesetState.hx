package states;

import data.PlayerSettings;
import data.Settings.WinCondition;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.SettingsMenuList;

class RulesetState extends FNFState
{
	static var lastSelected:Int = 0;

	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var iconScroll:FlxBackdrop;
	var transitioning:Bool = true;
	var items:SettingsMenuList;
	var descBG:FlxSprite;
	var descText:FlxText;
	var descTween:FlxTween;
	var camFollow:FlxObject;

	override function create()
	{
		transIn = transOut = null;

		camScroll = new FlxCamera();
		camScroll.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.5);
		FlxG.cameras.add(camScroll, false);
		camOver = new FlxCamera();
		camOver.bgColor = 0;
		FlxG.cameras.add(camOver, false);

		camFollow = new FlxObject(FlxG.width / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF21007F;
		bg.cameras = [FlxG.camera];
		add(bg);

		var stateText = new FlxText(0, 0, 0, 'Ruleset');
		stateText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stateText.screenCenter(X);
		stateText.scrollFactor.set();
		stateText.cameras = [camOver];
		camScroll.height = Math.ceil(stateText.height);

		iconScroll = new FlxBackdrop(Paths.getImage('menus/pvp/iconScroll'));
		iconScroll.alpha = 0.5;
		iconScroll.cameras = [camScroll];
		iconScroll.velocity.set(25, 25);
		iconScroll.scale.set(0.5, 0.5);

		add(iconScroll);
		add(stateText);

		descBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBG.scrollFactor.set();
		descBG.alpha = 0.8;
		descBG.cameras = [camOver];

		descText = new FlxText(0, 0, FlxG.width - 10);
		descText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.cameras = [camOver];

		items = new SettingsMenuList();
		items.onChange.add(onChange);
		items.controlsEnabled = false;
		add(items);

		addSetting({
			name: 'singleSongSelection',
			displayName: 'Single Song Selection',
			description: "If enabled, both players will pick one song instead of randomly picking from both players' selections.",
			type: CHECKBOX,
			defaultValue: false
		});
		addSetting({
			name: 'playbackRate',
			displayName: 'Playback Rate',
			description: "Change how slow or fast the song plays.",
			type: NUMBER,
			defaultValue: 1,
			displayFunction: function(value)
			{
				return value + 'x';
			},
			minValue: 0.5,
			maxValue: 2,
			decimals: 2,
			changeAmount: 0.05,
			holdDelay: 0.05
		});
		addSetting({
			name: 'randomEvents',
			displayName: 'Random Events',
			description: "Whether random events are enabled to spice up the gameplay.",
			type: CHECKBOX,
			defaultValue: true
		});
		addSetting({
			name: 'canDie',
			displayName: 'Can Die',
			description: "If enabled, health bars are added and players can die by losing all of their health.",
			type: CHECKBOX,
			defaultValue: true
		});
		addSetting({
			name: 'winCondition',
			displayName: 'Win Condition',
			description: "Choose the win condition.",
			type: STRING,
			defaultValue: WinCondition.SCORE,
			options: [WinCondition.SCORE, WinCondition.ACCURACY, WinCondition.MISSES]
		});
		addSetting({
			displayName: 'OK',
			description: "",
			type: ACTION,
		}, function()
		{
			transitioning = true;
			items.controlsEnabled = false;
			FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
				ease: FlxEase.expoIn
			});
			FlxFlicker.flicker(items.selectedItem, Main.TRANSITION_TIME, 0.06, true, false);
			camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, function()
			{
				FlxG.switchState(new SongSelectState());
			}, true);
		});

		items.selectItem(lastSelected);
		FlxG.camera.snapToTarget();

		add(descBG);
		add(descText);

		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				items.controlsEnabled = true;
			}
		});
		camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true, null, true);

		CoolUtil.playPvPMusic(0);
		FlxG.sound.music.fadeIn(Main.TRANSITION_TIME);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// prevent integer overflow (it would probably take an eternity for that to happen but you can never be too safe)
		if (iconScroll.x >= 300)
		{
			iconScroll.x -= 300;
		}
		if (iconScroll.y >= 300)
		{
			iconScroll.y -= 300;
		}

		if (!transitioning && PlayerSettings.checkAction(BACK_P))
		{
			transitioning = true;
			items.controlsEnabled = false;
			FlxG.sound.music.fadeOut(Main.TRANSITION_TIME);
			FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.sound.music.stop();
					FlxG.switchState(new MainMenuState());
				}
			});
			camOver.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, null, true);
		}

		descBG.y = descText.y - 2;
	}

	function onChange(item:SettingsMenuItem)
	{
		updateCamFollow(item);
		updateDesc(item, true);
		lastSelected = item.ID;
	}

	function updateCamFollow(item:SettingsMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function updateDesc(item:SettingsMenuItem, tween:Bool = false)
	{
		descText.text = item.data.description;
		descText.screenCenter(X);
		descText.y = FlxG.height - descText.height - 10;
		descBG.setGraphicSize(Std.int(descText.width + 4), Std.int(descText.height + 4));
		descBG.updateHitbox();
		descBG.setPosition(descText.x - 2, descText.y - 2);
		descBG.visible = descText.visible = descText.text.length > 0;

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

	function addSetting(data:SettingData, ?callback:Void->Void)
	{
		var item = new SettingsMenuItem(0, items.length * 140, data.displayName, callback, data);
		return items.addItem(item.name, item);
	}
}
