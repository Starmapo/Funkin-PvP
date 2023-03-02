package states;

import data.PlayerSettings;
import data.Settings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
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

		var bg = CoolUtil.createMenuBG();
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

	inline function switchPage(name:PageName)
	{
		onSwitch.dispatch(name);
	}

	inline function exit()
	{
		onExit.dispatch();
	}

	inline function get_camFollow()
	{
		return OptionsState.camFollow;
	}
}

class OptionsPage extends Page
{
	var items:TextMenuList;

	public function new()
	{
		super();

		items = new TextMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);

		createItem('Players', switchPage.bind(Players));
		createItem('Video', switchPage.bind(Video));
		createItem('Audio', switchPage.bind(Audio));
		createItem('Gameplay', switchPage.bind(Gameplay));
		createItem('Miscellaneous', switchPage.bind(Miscellaneous));
		createItem('Exit', exit);

		updateCamFollow(items.selectedItem);
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

	public function new()
	{
		super();

		items = new SettingsMenuList();
		items.onChange.add(onChange);
		items.onAccept.add(onAccept);
		add(items);
	}

	override function onAppear()
	{
		updateCamFollow(items.selectedItem);
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
	}

	function onAccept(item:SettingsMenuItem)
	{
		if (item.data.type == CHECKBOX)
		{
			item.value = !item.value;
		}
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
			changeAmount: 1
		});
		addSetting({
			name: 'smoothAudioTiming',
			displayName: 'Smooth Audio Timing',
			description: "If enabled, attempts to make the audio/frame timing update smoothly, instead of being set to the audio's exact position.",
			type: CHECKBOX,
			defaultValue: false
		});

		FlxG.log.add('${items.members[0].value}, ${items.members[0].data.name}, ${items.members[0].data.defaultValue}');
		FlxG.watch.add(Settings, 'globalOffset', 'globalOffset');
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
