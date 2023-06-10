package states.menus;

import data.CreditsData;
import data.Mods;
import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import ui.lists.MenuList;
import ui.lists.TextMenuList;
import util.DiscordClient;

class CreditsState extends FNFState
{
	static var DEFAULT_COLOR:FlxColor = 0xFF9271FD;
	static var lastSelected:Int = 0;

	var creditsArray:Array<CreditGroup> = [];
	var categoryMenuList:CreditsMenuList;
	var creditMenuList:CreditsMenuList;
	var bg:FlxSprite;
	var transitioning:Bool = true;
	var creditGroup:FlxTypedGroup<FlxText>;
	var creditDesc:FlxText;
	var creditLink:FlxText;
	var colorTween:FlxTween;

	override function destroy()
	{
		super.destroy();
		creditsArray = FlxDestroyUtil.destroyArray(creditsArray);
		categoryMenuList = null;
		creditMenuList = null;
		bg = null;
		creditGroup = null;
		creditDesc = null;
		creditLink = null;
		colorTween = null;
	}

	override function create()
	{
		DiscordClient.changePresence(null, "Credits Screen");

		transIn = transOut = null;

		bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = DEFAULT_COLOR;
		add(bg);

		var circleBG = new FlxSprite(0, 0, Paths.getImage('menus/credits/circleBG'));
		circleBG.antialiasing = true;
		add(circleBG);

		categoryMenuList = new CreditsMenuList();
		categoryMenuList.controlsEnabled = false;
		categoryMenuList.onChange.add(onChangeCategory);
		add(categoryMenuList);

		creditMenuList = new CreditsMenuList();
		creditMenuList.controlsEnabled = false;
		creditMenuList.visible = false;
		creditMenuList.onChange.add(onChangeCredit);
		add(creditMenuList);

		creditGroup = new FlxTypedGroup();
		add(creditGroup);

		creditDesc = new FlxText(FlxG.width, 0, (FlxG.width / 2) - 10, '', 32);
		creditDesc.screenCenter(Y);
		creditGroup.add(creditDesc);

		creditLink = new FlxText(creditDesc.x, creditDesc.y + creditDesc.height, creditDesc.fieldWidth, '', 24);
		creditGroup.add(creditLink);

		for (text in creditGroup)
		{
			text.scrollFactor.set();
			text.setFormat('PhantomMuff 1.5', text.size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		}

		readCredits('assets/data/credits');
		for (mod in Mods.currentMods)
			readCredits(Path.join([Mods.modsPath, mod.directory, 'data/credits.json']));

		categoryMenuList.selectItem(lastSelected);
		categoryMenuList.snapPositions();

		FlxG.camera.zoom = 3;
		var duration = Main.getTransitionTime();
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				categoryMenuList.controlsEnabled = true;
			}
		});
		FlxG.camera.fade(FlxColor.BLACK, duration, true, null, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.checkAction(BACK_P) && !transitioning)
		{
			transitioning = true;
			var duration = Main.getTransitionTime();
			if (creditMenuList.visible)
			{
				creditMenuList.controlsEnabled = false;
				for (text in creditGroup)
				{
					FlxTween.tween(text, {x: FlxG.width}, duration / 2, {ease: FlxEase.expoIn});
				}
				FlxTween.tween(FlxG.camera.scroll, {x: FlxG.width / 2}, duration / 2, {
					ease: FlxEase.expoIn,
					onComplete: function(_)
					{
						creditMenuList.visible = false;
						categoryMenuList.visible = true;
						FlxTween.tween(FlxG.camera.scroll, {x: 0}, duration / 2, {
							ease: FlxEase.expoOut,
							onComplete: function(_)
							{
								categoryMenuList.controlsEnabled = true;
								transitioning = false;
							}
						});
						doColorTween(DEFAULT_COLOR);
					}
				});
			}
			else
			{
				categoryMenuList.controlsEnabled = false;
				FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
					ease: FlxEase.expoIn,
					onComplete: function(_)
					{
						FlxG.switchState(new MainMenuState());
					}
				});
				FlxG.camera.fade(FlxColor.BLACK, duration, false, null, true);
			}
			CoolUtil.playCancelSound();
		}

		super.update(elapsed);
	}

	function readCredits(path:String, ?mod:String)
	{
		var data = Paths.getJson(path, mod);
		if (data != null && data.groups != null)
		{
			var creditsData = new CreditsData(data);
			for (i in 0...creditsData.groups.length)
			{
				var group = creditsData.groups[i];
				creditsArray.push(group);
				categoryMenuList.createItem(group.name, onAcceptCategory);
			}
		}
	}

	function onChangeCategory(selectedItem:CreditsMenuItem)
	{
		for (item in categoryMenuList)
		{
			item.targetY = item.ID - selectedItem.ID;
		}
		lastSelected = selectedItem.ID;
	}

	function onAcceptCategory()
	{
		creditMenuList.resetCredits(creditsArray[categoryMenuList.selectedIndex].credits, onAcceptCredit);
		categoryMenuList.controlsEnabled = false;
		var duration = Main.getTransitionTime();
		FlxTween.tween(FlxG.camera.scroll, {x: FlxG.width / 2}, duration / 2, {
			ease: FlxEase.expoIn,
			onComplete: function(_)
			{
				categoryMenuList.visible = false;
				creditMenuList.visible = true;
				creditMenuList.selectItem(0);
				creditMenuList.snapPositions();
				for (text in creditGroup)
				{
					FlxTween.tween(text, {x: (FlxG.width / 2) + 5}, duration / 2, {ease: FlxEase.expoOut});
				}
				FlxTween.tween(FlxG.camera.scroll, {x: 0}, duration / 2, {
					ease: FlxEase.expoOut,
					onComplete: function(_)
					{
						creditMenuList.controlsEnabled = true;
					}
				});
			}
		});
		CoolUtil.playScrollSound();
	}

	function resetCredit(credit:Credit)
	{
		creditDesc.y = 0;
		creditDesc.text = credit.description;
		creditLink.y = creditDesc.height + 5;
		creditLink.text = credit.link.length > 0 ? 'Press ACCEPT to go to:\n${credit.link}' : '';
		if (creditLink.text == '')
		{
			// hack to set its height to 0 when empty
			// otherwise it keeps the previous height. why?
			creditLink.updateHitbox();
			creditLink.height = 0;
		}
		CoolUtil.screenCenterGroup(creditGroup, Y);
		doColorTween(credit.color);
	}

	function doColorTween(color:FlxColor)
	{
		if (colorTween != null)
			colorTween.cancel();

		colorTween = FlxTween.color(bg, Main.getTransitionTime(), bg.color, color, {
			onComplete: function(_)
			{
				colorTween = null;
			}
		});
	}

	function getCredit(id:Int)
	{
		return creditsArray[categoryMenuList.selectedIndex].credits[id];
	}

	function onChangeCredit(selectedItem:CreditsMenuItem)
	{
		for (item in creditMenuList)
		{
			item.targetY = item.ID - selectedItem.ID;
		}
		resetCredit(getCredit(selectedItem.ID));
	}

	function onAcceptCredit()
	{
		var credit = getCredit(creditMenuList.selectedItem.ID);
		if (credit.link.length > 0)
			FlxG.openURL(credit.link);
	}
}

class CreditsMenuList extends TypedMenuList<CreditsMenuItem>
{
	var MAX_WIDTH:Float = (FlxG.width / 2) - 20;

	public function createItem(name:String, ?callback:Void->Void)
	{
		var item = new CreditsMenuItem(0, 0, name, callback, length);
		if (item.width > MAX_WIDTH)
		{
			var ratio = MAX_WIDTH / item.width;
			item.label.size = Math.floor(item.label.size * ratio);
		}
		return addItem(name, item);
	}

	public function resetCredits(credits:Array<Credit>, callback:Void->Void)
	{
		if (credits != null)
		{
			while (length > credits.length)
			{
				remove(members[length - 1], true);
			}
			for (i in 0...length)
			{
				var member = members[i];
				member.setItem(credits[i].name, callback);
			}
			while (length < credits.length)
			{
				createItem(credits[length].name, callback);
			}
		}
	}

	public function snapPositions()
	{
		for (item in members)
		{
			item.snapPosition();
		}
	}
}

class CreditsMenuItem extends TextMenuItem
{
	static var LERP:Float = 9.6;

	public var targetY:Int = 0;

	public function new(x:Float = 0, y:Float = 0, name:String, ?callback:Void->Void, targetY:Int = 0)
	{
		super(x, y, name, callback);
		this.targetY = targetY;
		snapPosition();
	}

	override function update(elapsed:Float)
	{
		x = FlxMath.lerp(x, getX(), elapsed * LERP);
		y = FlxMath.lerp(y, getY(), elapsed * LERP);

		super.update(elapsed);
	}

	public function snapPosition()
	{
		x = getX();
		y = getY();
	}

	function getX()
	{
		return (Math.abs(targetY) * -40) + 20;
	}

	function getY()
	{
		return (targetY * 156) + FlxG.height * 0.48;
	}
}
