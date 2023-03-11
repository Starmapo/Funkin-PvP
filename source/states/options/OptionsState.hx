package states.options;

import data.PlayerSettings;
import data.Settings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
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
		destroySubStates = false;

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

		var playersPage = addPage(Players, new PlayersPage());
		playersPage.onExit.add(switchPage.bind(Options));

		var videoPage = addPage(Video, new VideoPage());
		videoPage.onExit.add(switchPage.bind(Options));

		var audioPage = addPage(Audio, new AudioPage());
		audioPage.onExit.add(switchPage.bind(Options));

		var miscPage = addPage(Miscellaneous, new MiscellaneousPage());
		miscPage.onExit.add(switchPage.bind(Options));

		for (i in 0...2)
		{
			var playerPage = addPage(Player(i), new PlayerPage(i));
			playerPage.onExit.add(switchPage.bind(Players));

			var controlsPage = addPage(Controls(i), new ControlsPage(i));
			controlsPage.onExit.add(switchPage.bind(Player(i)));
		}

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
		camPages.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true, null, true);

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
		page.onOpenSubState.add(openSubState);
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
		FlxTween.tween(camPages, {y: FlxG.height}, Main.TRANSITION_TIME / 2, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				setPage(name);
				if (currentPage != null)
				{
					currentPage.controlsEnabled = false;
				}
				FlxTween.tween(camPages, {y: 0}, Main.TRANSITION_TIME / 2, {
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
		camPages.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, null, true);
	}

	inline function get_currentPage()
		return pages[currentName];
}
