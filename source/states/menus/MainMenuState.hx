package states.menus;

import flixel.text.FlxText;
import data.PlayerSettings;
import data.Settings;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.editors.ToolboxState;
import states.options.OptionsState;
import states.pvp.RulesetState;
import ui.lists.MenuList;
import ui.lists.TextMenuList;
import util.DiscordClient;

class MainMenuState extends FNFState
{
	static var lastSelected:Int = 0;

	var transitioning:Bool = true;
	var menuList:MainMenuList;
	var camFollow:FlxObject;
	var bg:FlxSprite;
	var magenta:FlxSprite;

	override function destroy()
	{
		super.destroy();
		menuList = null;
		camFollow = null;
		bg = null;
		magenta = null;
	}

	override function create()
	{
		DiscordClient.changePresence(null, "Main Menu");

		transIn = transOut = null;

		bg = CoolUtil.createMenuBG('menuBG', 1.2);
		bg.angle = 180;
		add(bg);

		if (Settings.flashing)
		{
			magenta = CoolUtil.createMenuBG('menuBGMagenta', 1.2);
			magenta.visible = false;
			add(magenta);
		}

		camFollow = new FlxObject(FlxG.width / 2);
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);

		menuList = new MainMenuList();
		menuList.createItem('PvP', function()
		{
			FlxG.switchState(new RulesetState());
		}, false, true);
		menuList.createItem('Credits', function()
		{
			FlxG.switchState(new CreditsState());
		});
		menuList.createItem('Toolbox', function()
		{
			FlxG.switchState(new ToolboxState());
		});
		menuList.createItem('Options', function()
		{
			FlxG.switchState(new OptionsState());
		});
		menuList.onChange.add(onChange);
		menuList.onAccept.add(onAccept);
		menuList.selectItem(lastSelected);
		menuList.controlsEnabled = false;
		add(menuList);

		FlxG.camera.snapToTarget();
		bg.y = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);
		if (magenta != null)
			magenta.y = bg.y;

		var version = FlxG.stage.application.meta["version"];
		var versionText = new FlxText(5, FlxG.height - 5, FlxG.width - 10, 'Version: $version');
		versionText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		versionText.y -= versionText.height;
		versionText.scrollFactor.set();
		add(versionText);

		FlxG.camera.zoom = 3;
		var duration = Main.getTransitionTime();
		FlxTween.tween(bg, {angle: 0}, duration, {ease: FlxEase.quartInOut});
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				menuList.controlsEnabled = true;
			}
		});
		FlxG.camera.fade(FlxColor.BLACK, duration, true, null, true);

		CoolUtil.playConfirmSound(0);
		if (!FlxG.sound.musicPlaying)
		{
			CoolUtil.playMenuMusic(0);
			FlxG.sound.music.fadeIn(duration);
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		var bgY = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);
		bg.y = FlxMath.lerp(bg.y, bgY, elapsed * 6);

		if (PlayerSettings.checkAction(BACK_P) && !transitioning)
		{
			var duration = Main.getTransitionTime();
			FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.switchState(new TitleState());
				}
			});
			FlxG.camera.fade(FlxColor.WHITE, duration, false, null, true);
			CoolUtil.playCancelSound();
			transitioning = true;
		}

		super.update(elapsed);

		if (magenta != null)
		{
			magenta.y = bg.y;
			magenta.angle = bg.angle;
		}
	}

	function updateCamFollow()
	{
		var midpoint = menuList.selectedItem.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onChange(item:MainMenuItem)
	{
		updateCamFollow();
		lastSelected = item.ID;
	}

	function onAccept(selectedItem:MainMenuItem)
	{
		if (selectedItem.callback == null || transitioning)
			return;

		if (selectedItem.fireInstantly)
		{
			selectedItem.callback();
		}
		else
		{
			transitioning = true;
			menuList.controlsEnabled = false;
			var duration = Main.getTransitionTime();
			menuList.forEach(function(item)
			{
				if (item != selectedItem)
				{
					FlxTween.tween(item, {x: item.x - FlxG.width}, duration, {ease: FlxEase.backIn});
				}
			});
			FlxG.camera.fade(FlxColor.BLACK, duration, false, null, true);
			if (selectedItem.fadeMusic)
			{
				FlxG.sound.music.fadeOut(duration, 0);
			}
			FlxTween.tween(bg, {angle: 45}, duration, {ease: FlxEase.expoIn});
			FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {ease: FlxEase.expoIn});
			if (magenta != null)
				FlxFlicker.flicker(magenta, duration, 0.15, false);
			FlxFlicker.flicker(selectedItem, duration, 0.06, true, false, function(_)
			{
				if (selectedItem.fadeMusic)
					FlxG.sound.music.stop();

				selectedItem.callback();
			});
			CoolUtil.playConfirmSound();
		}
	}
}

class MainMenuList extends TypedMenuList<MainMenuItem>
{
	public function new()
	{
		super();
		fireCallbacks = false;
		CoolUtil.playConfirmSound(0);
	}

	public function createItem(name:String, ?callback:Void->Void, fireInstantly:Bool = false, fadeMusic:Bool = false)
	{
		var item = new MainMenuItem(0, 150 * length, name, callback, fireInstantly, fadeMusic);
		item.screenCenter(X);
		var targetX = item.x;
		item.x -= FlxG.width;
		var duration = Main.getTransitionTime();
		FlxTween.tween(item, {x: targetX}, duration, {ease: FlxEase.expoInOut});
		return addItem(name, item);
	}
}

class MainMenuItem extends TextMenuItem
{
	public var fireInstantly:Bool = false;
	public var fadeMusic:Bool = false;

	var targetScale:Float = 1;
	var lerp:Float = 15;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, fireInstantly:Bool = false, fadeMusic:Bool = false)
	{
		super(x, y, name, callback, 98);
		this.fireInstantly = fireInstantly;
		this.fadeMusic = fadeMusic;
		label.scale.set(targetScale, targetScale);
	}

	override function update(elapsed:Float)
	{
		if (label != null)
			label.scale.set(FlxMath.lerp(label.scale.x, targetScale, elapsed * lerp), FlxMath.lerp(label.scale.y, targetScale, elapsed * lerp));

		super.update(elapsed);
	}

	override function idle()
	{
		if (label != null)
		{
			label.color = FlxColor.WHITE;
			label.borderColor = FlxColor.BLACK;
		}
		targetScale = 1;
	}

	override function select()
	{
		if (label != null)
		{
			label.color = FlxColor.BLACK;
			label.borderColor = FlxColor.WHITE;
		}
		targetScale = 1.2;
	}
}
