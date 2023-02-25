package states;

import data.PlayerSettings;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.MenuList;
import ui.TextMenuList.TextMenuItem;

class MainMenuState extends FNFState
{
	static var lastSelected:Int = 0;

	var transitioning:Bool = true;
	var menuList:MainMenuList;
	var camFollow:FlxObject;
	var bg:FlxSprite;

	override function create()
	{
		transIn = transOut = null;

		bg = CoolUtil.createMenuBG('menuBG', 1.2);
		bg.scrollFactor.set();
		add(bg);

		camFollow = new FlxObject();
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);

		menuList = new MainMenuList();
		menuList.createItem('PvP', function() {});
		menuList.createItem('Credits', function() {});
		menuList.createItem('Options', function() {});
		menuList.onChange.add(onChange);
		menuList.selectItem(lastSelected);
		add(menuList);

		FlxG.camera.snapToTarget();
		bg.y = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);

		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
			}
		});
		FlxG.camera.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		var bgY = FlxMath.remapToRange(menuList.selectedIndex, 0, menuList.length - 1, 0, FlxG.height - bg.height);
		bg.y = FlxMath.lerp(bg.y, bgY, 0.1);

		if (PlayerSettings.checkAction(BACK_P) && !transitioning)
		{
			FlxTween.tween(FlxG.camera, {zoom: 5}, Main.TRANSITION_TIME, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.switchState(new TitleState());
				}
			});
			FlxG.camera.fade(FlxColor.WHITE, Main.TRANSITION_TIME);
			CoolUtil.playCancelSound();
			transitioning = true;
		}

		super.update(elapsed);
	}

	function updateFollow()
	{
		var midpoint = menuList.selectedItem.getMidpoint();
		camFollow.setPosition(midpoint.x, midpoint.y);
		midpoint.put();
	}

	function onChange(item:MainMenuItem)
	{
		updateFollow();
		lastSelected = item.ID;
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

	public function createItem(name:String, ?callback:Void->Void, fireInstantly:Bool = false)
	{
		var item = new MainMenuItem(0, 150 * length, name, callback, fireInstantly);
		item.screenCenter(X);
		return addItem(name, item);
	}
}

class MainMenuItem extends TextMenuItem
{
	public var fireInstantly:Bool = false;

	var targetScale:Float = 1;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, fireInstantly:Bool = false)
	{
		super(x, y, name, callback, 98);
		this.fireInstantly = fireInstantly;
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
