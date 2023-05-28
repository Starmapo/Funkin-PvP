package states.options;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.menus.MainMenuState;
import util.DiscordClient;

class OptionsState extends FNFState
{
	public static var camFollow:FlxObject;

	var pages:Map<PageName, Page> = new Map();
	var currentName:PageName = Options;
	var currentPage(get, never):Page;
	var camPages:FlxCamera;
	var nextState:FlxState;

	public function new(?nextState:FlxState)
	{
		super();
		if (nextState == null)
			nextState = new MainMenuState();
		this.nextState = nextState;
	}

	override function create()
	{
		DiscordClient.changePresence(null, "Options Menu");

		transIn = transOut = null;
		destroySubStates = false;

		camPages = new FlxCamera();
		camPages.bgColor = 0;
		FlxG.cameras.add(camPages, false);

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF5C6CA5;
		add(bg);

		camFollow = new FlxObject(FlxG.width / 2);
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

		var gameplayPage = addPage(Gameplay, new GameplayPage());
		gameplayPage.onExit.add(switchPage.bind(Options));

		var miscPage = addPage(Miscellaneous, new MiscellaneousPage());
		miscPage.onExit.add(switchPage.bind(Options));

		for (i in 0...2)
		{
			var playerPage = addPage(Player(i), new PlayerPage(i));
			playerPage.onExit.add(switchPage.bind(Players));

			var controlsPage = addPage(Controls(i), new ControlsPage(i));
			controlsPage.onExit.add(switchPage.bind(Player(i)));

			var noteSkinPage = addPage(NoteSkin(i), new NoteSkinPage(i));
			noteSkinPage.onExit.add(switchPage.bind(Player(i)));

			var judgementSkinPage = addPage(JudgementSkin(i), new JudgementSkinPage(i));
			judgementSkinPage.onExit.add(switchPage.bind(Player(i)));

			var splashSkinPage = addPage(SplashSkin(i), new SplashSkinPage(i));
			splashSkinPage.onExit.add(switchPage.bind(Player(i)));
		}

		currentPage.onAppear();
		camPages.snapToTarget();
		FlxG.camera.zoom = 3;
		var duration = Main.getTransitionTime();
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				currentPage.controlsEnabled = true;
			}
		});
		camPages.fade(FlxColor.BLACK, duration, true, null, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		camPages.zoom = FlxG.camera.zoom;
	}

	override function destroy()
	{
		super.destroy();
		camFollow = null;
		pages = null;
		camPages = null;
		nextState = null;
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
		var duration = Main.getTransitionTime();
		FlxTween.tween(camPages, {y: FlxG.height}, duration / 2, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				setPage(name);
				if (currentPage != null)
				{
					currentPage.controlsEnabled = false;
				}
				FlxTween.tween(camPages, {y: 0}, duration / 2, {
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

		if (currentPage != null)
			DiscordClient.changePresence(currentPage.rpcDetails, 'Options Menu');
		else
			DiscordClient.changePresence(null, 'Options Menu');
	}

	function exitToMainMenu()
	{
		if (currentPage != null)
		{
			currentPage.controlsEnabled = false;
		}
		var duration = Main.getTransitionTime();
		FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				FlxG.switchState(nextState);
			}
		});
		camPages.fade(FlxColor.BLACK, duration, false, null, true);
	}

	inline function get_currentPage()
		return pages[currentName];
}
