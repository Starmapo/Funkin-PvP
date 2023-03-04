package states;

import data.PlayerSettings;
import data.Settings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import ui.SettingsMenuList;
import ui.TextMenuList;

class OptionsState extends FNFState
{
	public static var camFollow:FlxObject;

	var pages:Map<PageName, Page> = new Map();
	var currentName:PageName = Options;
	var currentPage(get, never):Page;
	var camPages:FlxCamera;

	override function create()
	{
		transIn = transOut = null;

		camPages = new FlxCamera();
		camPages.bgColor = 0;
		FlxG.cameras.add(camPages, false);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF5C6CA5;
		add(bg);

		camFollow = new FlxObject();
		camPages.follow(camFollow, LOCKON, 0.1);
		add(camFollow);

		var optionsPage = addPage(Options, new OptionsPage());
		optionsPage.onExit.add(exitToMainMenu);
		optionsPage.controlsEnabled = false;

		var audioPage = addPage(Audio, new AudioPage());
		audioPage.onExit.add(switchPage.bind(Options));

		currentPage.onAppear();
		camPages.snapToTarget();
		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onUpdate: function(_)
			{
				camPages.zoom = FlxG.camera.zoom;
			},
			onComplete: function(_)
			{
				currentPage.controlsEnabled = true;
			}
		});
		camPages.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true);

		super.create();
	}

	override function destroy()
	{
		super.destroy();
		camFollow = null;
	}

	function addPage<T:Page>(name:PageName, page:T)
	{
		page.onSwitch.add(switchPage);
		pages[name] = page;
		add(page);
		page.exists = currentName == name;
		page.cameras = [camPages];
		return page;
	}

	function switchPage(name:PageName)
	{
		if (currentPage != null)
		{
			currentPage.controlsEnabled = false;
		}
		FlxTween.tween(camPages, {y: FlxG.height}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				setPage(name);
				if (currentPage != null)
				{
					currentPage.controlsEnabled = false;
				}
				FlxTween.tween(camPages, {y: 0}, Main.TRANSITION_TIME, {
					ease: FlxEase.expoOut,
					onComplete: function(_)
					{
						if (currentPage != null)
						{
							currentPage.controlsEnabled = true;
						}
					}
				});
			}
		});
	}

	function setPage(name:PageName)
	{
		if (currentPage != null)
			currentPage.exists = false;

		currentName = name;

		if (currentPage != null)
		{
			currentPage.exists = true;
			currentPage.onAppear();
			camPages.snapToTarget();
		}
	}

	function exitToMainMenu()
	{
		if (currentPage != null)
		{
			currentPage.controlsEnabled = false;
		}
		FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoIn,
			onUpdate: function(_)
			{
				camPages.zoom = FlxG.camera.zoom;
			},
			onComplete: function(_)
			{
				FlxG.switchState(new MainMenuState());
			}
		});
		camPages.fade(FlxColor.BLACK, Main.TRANSITION_TIME);
	}

	inline function get_currentPage()
		return pages[currentName];
}

class Page extends FlxGroup
{
	public var controlsEnabled:Bool = true;
	public var onSwitch(default, null) = new FlxTypedSignal<PageName->Void>();
	public var onExit(default, null) = new FlxSignal();

	var camFollow(get, never):FlxObject;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		if (controlsEnabled)
			updateControls();

		super.update(elapsed);
	}

	public function onAppear() {}

	function updateControls()
	{
		if (PlayerSettings.checkAction(BACK_P))
		{
			CoolUtil.playCancelSound();
			exit();
		}
	}

	function exit()
	{
		onExit.dispatch();
	}

	inline function switchPage(name:PageName)
	{
		onSwitch.dispatch(name);
	}

	inline function get_camFollow()
	{
		return OptionsState.camFollow;
	}
}

class OptionsPage extends Page
{
	static var lastSelected:Int = 0;

	var items:TextMenuList;

	public function new()
	{
		super();

		items = new TextMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		// createItem('Players', switchPage.bind(Players));
		// createItem('Video', switchPage.bind(Video));
		createItem('Audio', switchPage.bind(Audio));
		// createItem('Gameplay', switchPage.bind(Gameplay));
		// createItem('Miscellaneous', switchPage.bind(Miscellaneous));
		createItem('Exit', exit);

		items.selectItem(lastSelected);
	}

	override function onAppear()
	{
		updateCamFollow(items.selectedItem);
	}

	function createItem(name:String, ?callback:Void->Void)
	{
		var item = new TextMenuItem(0, items.length * 100, name, callback);
		item.screenCenter(X);
		return items.addItem(name, item);
	}

	function updateCamFollow(item:TextMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.setPosition(midpoint.x, midpoint.y);
		midpoint.put();
	}

	function onChange(item:TextMenuItem)
	{
		updateCamFollow(item);
	}

	function onAccept(item:TextMenuItem)
	{
		CoolUtil.playConfirmSound();
	}
}

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
	}

	override function exit()
	{
		Settings.saveData();
		super.exit();
	}

	function addSetting(data:SettingData, ?callback:Void->Void)
	{
		return items.createItem(data, callback);
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
}

class AudioPage extends BaseSettingsPage
{
	public function new()
	{
		super();

		addSetting({
			name: 'globalOffset',
			displayName: 'Global Offset',
			description: "An offset to apply to every song.",
			type: NUMBER,
			defaultValue: 0,
			displayFormat: '%v ms',
			minValue: -300,
			maxValue: 300,
			changeAmount: 1,
			holdDelay: 0,
			holdMult: 2
		});
		addSetting({
			name: 'smoothAudioTiming',
			displayName: 'Smooth Audio Timing',
			description: "If enabled, attempts to make the audio/frame timing move smoothly, instead of being set to the audio's exact position.",
			type: CHECKBOX,
			defaultValue: false
		});
	}
}

enum PageName
{
	Options;
	Players;
	Video;
	Audio;
	Gameplay;
	Miscellaneous;
}
