package states;

import data.PlayerSettings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
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

		var options = addPage(Options, new OptionsPage());
		options.onExit.add(exitToMainMenu);
		options.controlsEnabled = false;

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

		createItem('General', switchPage.bind(General));
		createItem('Graphics', switchPage.bind(Graphics));
		createItem('Preferences', switchPage.bind(Preferences));
		createItem('Players', switchPage.bind(Players));
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

enum PageName
{
	Options;
	General;
	Graphics;
	Preferences;
	Players;
}
