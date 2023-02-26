package states;

import data.CreditsData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.MenuList;
import ui.TextMenuList;

class CreditsState extends FNFState
{
	static var lastSelected:Int = 0;

	var credits:Array<CreditsData> = [];
	var categoryMenuList:CreditsMenuList;
	var creditMenuList:CreditsMenuList;
	var bg:FlxSprite;
	var transitioning:Bool = true;

	override function create()
	{
		transIn = transOut = null;

		bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0x9271FD;
		add(bg);

		categoryMenuList = new CreditsMenuList();
		categoryMenuList.controlsEnabled = false;
		categoryMenuList.onChange.add(onChangeCategory);
		add(categoryMenuList);

		creditMenuList = new CreditsMenuList();
		creditMenuList.controlsEnabled = false;
		add(creditMenuList);

		readCredits('assets/data/credits');
		for (i in 0...9)
		{
			categoryMenuList.createItem('Mod $i');
		}

		categoryMenuList.selectItem(lastSelected);

		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, Main.TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				categoryMenuList.controlsEnabled = true;
			}
		});
		FlxG.camera.fade(FlxColor.BLACK, Main.TRANSITION_TIME, true);

		super.create();
	}

	function readCredits(path:String, ?mod:String)
	{
		var data = Paths.getJson(path, mod);
		if (data != null && data.credits != null)
		{
			var creditsData = new CreditsData(data);
			if (mod != null)
			{
				creditsData.directory = mod;
			}
			else
			{
				creditsData.directory = "Friday Night Funkin' PvP";
			}
			credits.push(creditsData);

			categoryMenuList.createItem(creditsData.directory);
		}
	}

	function onChangeCategory(selectedItem:CreditsMenuItem)
	{
		for (item in categoryMenuList)
		{
			item.targetY = item.ID - selectedItem.ID;
		}
	}
}

class CreditsMenuList extends TypedMenuList<CreditsMenuItem>
{
	static var MAX_WIDTH:Float = (FlxG.width / 2) - 45;

	public function createItem(name:String, ?callback:Void->Void)
	{
		var item = new CreditsMenuItem(0, 0, name, callback);
		var ogSize = item.label.size;
		if (item.width > MAX_WIDTH)
		{
			var ratio = MAX_WIDTH / item.width;
			item.label.size = Math.floor(item.label.size * ratio);
			FlxG.log.add('$ogSize, ${item.label.size}, $ratio');
		}
		item.targetY = length;
		return addItem(name, item);
	}
}

class CreditsMenuItem extends TextMenuItem
{
	static var LERP:Float = 0.16;

	public var targetY:Int = 0;

	override function update(elapsed:Float)
	{
		x = CoolUtil.lerp(x, getX(), LERP);
		y = CoolUtil.lerp(y, getY(), LERP);

		super.update(elapsed);
	}

	public function snapPosition()
	{
		x = getX();
		y = getY();
	}

	function getX()
	{
		return (Math.abs(targetY) * -20) + 45;
	}

	function getY()
	{
		return (targetY * 156) + FlxG.height * 0.48;
	}
}
