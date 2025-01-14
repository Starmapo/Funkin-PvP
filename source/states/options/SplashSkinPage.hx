package states.options;

import backend.settings.PlayerConfig;
import backend.structures.skin.SplashSkin;
import backend.util.StringUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import objects.game.NoteSplash;
import objects.menus.lists.SkinCategoryList;
import objects.menus.lists.SkinList;
import objects.menus.lists.TextMenuList;

class SplashSkinPage extends Page
{
	var player:Int = 0;
	var categoryList:SkinCategoryList;
	var skinList:SkinList;
	var config:PlayerConfig;
	var lastSkin:SkinItem;
	var skinGroup:FlxTypedGroup<FlxSprite>;
	var bg:FlxSprite;
	var splashTimer:FlxTimer;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		config = Settings.playerConfigs[player];
		rpcDetails = 'Player ${player + 1} Splash Skin';
		
		skinGroup = new FlxTypedGroup();
		add(skinGroup);
		
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGBFloat(0, 0, 0, 0.6));
		bg.setGraphicSize(Std.int(FlxG.width / 2), FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);
		
		categoryList = new SkinCategoryList();
		categoryList.onChange.add(onChangeCategory);
		categoryList.onAccept.add(onAcceptCategory);
		
		skinList = new SkinList();
		skinList.onChange.add(onChangeSkin);
		skinList.onAccept.add(onAcceptSkin);
		skinList.controlsEnabled = false;
		
		add(skinList);
		add(categoryList);
		
		var groups:Array<ModSkins> = [];
		for (_ => group in Mods.skins)
		{
			if (group.splashSkins.length > 0)
				groups.push(group);
		}
		groups.sort(function(a, b)
		{
			return StringUtil.sortAlphabetically(a.name, b.name);
		});
		
		for (group in groups)
			categoryList.createItem(group);
			
		categoryList.selectItem(0);
		
		addPageTitle('Splash Skin');
	}
	
	override function destroy()
	{
		super.destroy();
		categoryList = null;
		skinList = null;
		config = null;
	}
	
	override function updateControls()
	{
		if (Controls.anyJustPressed(BACK))
		{
			if (skinList.visible)
			{
				skinList.visible = skinList.controlsEnabled = false;
				categoryList.visible = categoryList.controlsEnabled = true;
				updateCamFollow(categoryList.selectedItem);
			}
			else
				exit();
			CoolUtil.playCancelSound();
		}
	}
	
	override function onAppear()
	{
		updateCamFollow(categoryList.selectedItem);
	}
	
	function updateCamFollow(item:TextMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
	
	function onChangeCategory(item:SkinCategoryItem)
	{
		updateCamFollow(item);
	}
	
	function onAcceptCategory(item:SkinCategoryItem)
	{
		reloadSkins(item.skins);
		categoryList.visible = categoryList.controlsEnabled = false;
		skinList.visible = skinList.controlsEnabled = true;
		CoolUtil.playScrollSound();
	}
	
	function onChangeSkin(item:SkinItem)
	{
		updateCamFollow(item);
		reloadSkin(item);
	}
	
	function onAcceptSkin(item:SkinItem)
	{
		if (lastSkin == item)
			return;
			
		if (lastSkin != null)
		{
			FlxTween.cancelTweensOf(lastSkin);
			CoolUtil.tweenColor(lastSkin, 0.5, lastSkin.color, FlxColor.WHITE);
		}
		config.splashSkin = item.name;
		FlxTween.cancelTweensOf(item);
		CoolUtil.tweenColor(item, 0.5, item.color, FlxColor.LIME);
		lastSkin = item;
		CoolUtil.playConfirmSound();
	}
	
	function reloadSkin(item:SkinItem)
	{
		skinGroup.forEach(function(spr)
		{
			spr.destroy();
		});
		skinGroup.clear();
		
		var skin = SplashSkin.loadSkinFromName(item.skin.mod + ':' + item.skin.name);
		var splashes:Array<NoteSplash> = [];
		for (i in 0...4)
		{
			var splash = new NoteSplash(i, skin);
			if (i == 0)
				splash.startSplash();
			splash.x = ((FlxG.width / 2) - splash.width) / 2 + (FlxG.width / 2);
			splash.screenCenter(Y);
			skinGroup.add(splash);
			splashes.push(splash);
		}
		
		if (splashTimer == null)
			splashTimer = new FlxTimer();
		else
			splashTimer.cancel();
			
		var curSplash = 0;
		splashTimer.start(0.5, function(tmr)
		{
			splashes[curSplash].visible = false;
			
			curSplash++;
			if (curSplash > 3)
				curSplash = 0;
				
			var splash = splashes[curSplash];
			splash.startSplash();
			splash.visible = true;
		}, 0);
	}
	
	function reloadSkins(skins:ModSkins)
	{
		skinList.forEach(function(spr)
		{
			spr.destroy();
		});
		skinList.clear();
		lastSkin = null;
		for (skin in skins.splashSkins)
		{
			var item = skinList.createItem(skin);
			if (skin.mod + ':' + skin.name == config.splashSkin)
			{
				item.color = FlxColor.LIME;
				lastSkin = item;
			}
		}
		skinList.selectItem(0);
	}
}
