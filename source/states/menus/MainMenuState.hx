package states.menus;

import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.options.OptionsState;
import states.pvp.RulesetState;
import ui.lists.MenuList;
import ui.lists.TextMenuList;

class MainMenuState extends FNFState
{
	static var lastSelected:Int = 0;

	var transitioning:Bool = true;
	var menuList:MainMenuList;
	var camFollow:FlxObject;
	var bg:FlxSprite;
	var magenta:FlxSprite;

	override function create()
	{
		transIn = transOut = null;

		bg = CoolUtil.createMenuBG('menuBG', 1.2);
		bg.scrollFactor.set();
		bg.angle = 180;
		add(bg);

		magenta = CoolUtil.createMenuBG('menuBGMagenta', 1.2);
		magenta.scrollFactor.set();
		magenta.visible = false;
		add(magenta);

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
		magenta.y = bg.y = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);

		FlxG.camera.zoom = 3;
		FlxTween.tween(bg, {angle: 0}, Main.TRANSITION_TIME, {ease: FlxEase.quartInOut});
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				menuList.controlsEnabled = true;
			}
		});
		FlxG.camera.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true, null, true);

		CoolUtil.playConfirmSound(0);
		if (!FlxG.sound.musicPlaying)
		{
			CoolUtil.playMenuMusic(0);
			FlxG.sound.music.fadeIn(Main.TRANSITION_TIME);
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		var bgY = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);
		magenta.y = bg.y = FlxMath.lerp(bg.y, bgY, 0.1);
		magenta.angle = bg.angle;

		if (PlayerSettings.checkAction(BACK_P) && !transitioning)
		{
			FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.switchState(new TitleState());
				}
			});
			FlxG.camera.fade(FlxColor.WHITE, Main.TRANSITION_TIME, false, null, true);
			CoolUtil.playCancelSound();
			transitioning = true;
		}

		super.update(elapsed);
	}

	function updateFollow()
	{
		var midpoint = menuList.selectedItem.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}

	function onChange(item:MainMenuItem)
	{
		updateFollow();
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
			menuList.forEach(function(item)
			{
				if (item != selectedItem)
				{
					FlxTween.tween(item, {x: item.x - FlxG.width}, Main.TRANSITION_TIME, {ease: FlxEase.backIn});
				}
			});
			FlxG.camera.fade(FlxColor.BLACK, Main.TRANSITION_TIME, false, null, true);
			if (selectedItem.fadeMusic)
			{
				FlxG.sound.music.fadeOut(Main.TRANSITION_TIME, 0);
			}
			FlxTween.tween(bg, {angle: 45}, Main.TRANSITION_TIME, {ease: FlxEase.expoIn});
			FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {ease: FlxEase.expoIn});
			FlxFlicker.flicker(magenta, Main.TRANSITION_TIME, 0.15, false);
			FlxFlicker.flicker(selectedItem, Main.TRANSITION_TIME, 0.06, true, false, function(_)
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
		FlxTween.tween(item, {x: targetX}, Main.TRANSITION_TIME, {ease: FlxEase.expoInOut});
		return addItem(name, item);
	}
}

class MainMenuItem extends TextMenuItem
{
	public var fireInstantly:Bool = false;
	public var fadeMusic:Bool = false;

	var targetScale:Float = 1;

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
		{
			var lerp = CoolUtil.getLerp(0.25);
			label.scale.set(FlxMath.lerp(label.scale.x, targetScale, lerp), FlxMath.lerp(label.scale.y, targetScale, lerp));
		}

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
