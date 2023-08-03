package states.options;

import backend.settings.PlayerConfig;
import backend.structures.skin.JudgementSkin;
import backend.util.StringUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.game.JudgementDisplay;
import objects.menus.lists.SkinCategoryList;
import objects.menus.lists.SkinList;
import objects.menus.lists.TextMenuList;

class JudgementSkinPage extends Page
{
	var player:Int = 0;
	var categoryList:SkinCategoryList;
	var skinList:SkinList;
	var config:PlayerConfig;
	var lastSkin:SkinItem;
	var skinGroup:FlxTypedGroup<FlxSprite>;
	var bg:FlxSprite;
	
	public function new(player:Int)
	{
		super();
		this.player = player;
		config = Settings.playerConfigs[player];
		rpcDetails = 'Player ${player + 1} Judgement Skin';
		
		skinGroup = new FlxTypedGroup();
		add(skinGroup);
		
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.fromRGBFloat(0, 0, 0, 0.6));
		bg.setGraphicSize(FlxG.width / 2, FlxG.height);
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
			if (group.judgementSkins.length > 0)
				groups.push(group);
		}
		groups.sort(function(a, b)
		{
			return StringUtil.sortAlphabetically(a.name, b.name);
		});
		
		for (group in groups)
			categoryList.createItem(group);
			
		categoryList.selectItem(0);
		
		addPageTitle('Judgement Skin');
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
		if (PlayerSettings.checkAction(BACK_P))
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
			FlxTween.color(lastSkin, 0.5, lastSkin.color, FlxColor.WHITE);
		}
		config.judgementSkin = item.name;
		FlxTween.cancelTweensOf(item);
		FlxTween.color(item, 0.5, item.color, FlxColor.LIME);
		lastSkin = item;
		CoolUtil.playConfirmSound();
	}
	
	function reloadSkin(item:SkinItem)
	{
		skinGroup.destroyMembers();
		
		var skin = JudgementSkin.loadSkinFromName(item.skin.mod + ':' + item.skin.name);
		var graphics:Array<FlxGraphic> = [];
		for (i in 0...6)
		{
			var graphic = JudgementDisplay.getJudgementGraphic(i, skin);
			if (graphic != null && !graphics.contains(graphic))
				graphics.push(graphic);
		}
		
		var curY:Float = 0;
		for (i in 0...graphics.length)
		{
			var judgement = new FlxSprite(FlxG.width / 2, curY, graphics[i]);
			judgement.scale.scale(skin.scale * 2);
			judgement.updateHitbox();
			judgement.antialiasing = skin.antialiasing;
			judgement.x += (FlxG.width / 2 - judgement.width) / 2;
			judgement.active = false;
			judgement.scrollFactor.set();
			skinGroup.add(judgement);
			
			curY += judgement.height + 5;
		}
		
		var newY = (FlxG.height - CoolUtil.getGroupHeight(skinGroup)) / 2;
		for (obj in skinGroup)
			obj.y += newY;
	}
	
	function reloadSkins(skins:ModSkins)
	{
		skinList.destroyMembers();
		lastSkin = null;
		for (skin in skins.judgementSkins)
		{
			var item = skinList.createItem(skin);
			if (skin.mod + ':' + skin.name == config.judgementSkin)
			{
				item.color = FlxColor.LIME;
				lastSkin = item;
			}
		}
		skinList.selectItem(0);
	}
}
