package states.menus;

import data.Mods.Mod;
import data.Mods;
import data.PlayerSettings;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import haxe.io.Path;
import ui.editors.Tooltip;
import ui.lists.MenuList.TypedMenuItem;
import ui.lists.MenuList.TypedMenuList;

class ModsState extends FNFState
{
	static var lastSelected:Int = 0;
	
	var items:ModList;
	var camFollow:FlxObject;
	var transitioning:Bool = true;
	var tooltip:Tooltip;
	
	override function create()
	{
		var bg = CoolUtil.createMenuBG('menuBG');
		add(bg);
		
		camFollow = new FlxObject(FlxG.width / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);
		
		items = new ModList();
		items.controlsEnabled = false;
		items.onChange.add(onChange);
		add(items);
		
		tooltip = new Tooltip();
		tooltip.scrollFactor.set();
		add(tooltip);
		
		Mods.reloadMods();
		for (mod in Mods.currentMods)
		{
			var item = items.createItem(mod);
			if (item.warningIcon != null)
				tooltip.addTooltip(item.warningIcon, mod.warnings.join('\n'));
		}
		
		if (lastSelected >= items.length)
			lastSelected = items.length - 1;
		items.selectItem(lastSelected);
		FlxG.camera.snapToTarget();
		
		FlxG.camera.zoom = 3;
		var duration = Main.getTransitionTime();
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				items.controlsEnabled = true;
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
			items.controlsEnabled = false;
			var duration = Main.getTransitionTime();
			FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
				ease: FlxEase.expoIn,
				onComplete: function(_)
				{
					FlxG.switchState(new MainMenuState());
				}
			});
			FlxG.camera.fade(FlxColor.BLACK, duration, false, null, true);
		}
		
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
	
	override function destroy()
	{
		super.destroy();
		items = null;
		camFollow = null;
		tooltip = null;
	}
	
	function updateCamFollow(item:ModItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
	
	function onChange(item:ModItem)
	{
		updateCamFollow(item);
	}
}

class ModList extends TypedMenuList<ModItem>
{
	public function createItem(mod:Mod)
	{
		var item = new ModItem(0, length * 400, mod);
		item.screenCenter(X);
		return addItem(item.name, item);
	}
}

class ModItem extends TypedMenuItem<FlxSpriteGroup>
{
	public var warningIcon:FlxSprite;
	
	public function new(x:Float = 0, y:Float = 0, mod:Mod)
	{
		var label = new FlxSpriteGroup();
		
		super(x, y, label, mod.id);
		
		final bgEllipse = 20;
		
		var bgGraphic = FlxG.bitmap.get('mod_bg');
		if (bgGraphic == null)
		{
			var spr = new FlxSprite().makeGraphic(FlxG.width - 50, Std.int(FlxG.height / 2), FlxColor.TRANSPARENT, false, 'mod_bg');
			FlxSpriteUtil.drawRoundRect(spr, 0, 0, spr.width, spr.height, bgEllipse, bgEllipse, FlxColor.GRAY, {thickness: 4});
			bgGraphic = spr.graphic;
			bgGraphic.destroyOnNoUse = false;
			spr.destroy();
		}
		var bg = new FlxSprite(0, 0, bgGraphic);
		
		var iconImage = Paths.getImage(Path.join([Mods.modRoot, mod.id, 'icon']), null, false);
		if (iconImage == null)
			iconImage = Paths.getImage('menus/mods/noIcon');
		var icon = new FlxSprite(bgEllipse, bgEllipse, iconImage);
		
		var maxNameWidth = bg.width - 109;
		var name = new FlxText(icon.x + icon.width + 5, icon.y + (icon.height / 2), 0, mod.title);
		name.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (name.width > maxNameWidth)
		{
			var ratio = maxNameWidth / name.width;
			name.size *= Math.floor(ratio);
		}
		name.y -= name.height / 2;
		
		var count = getCountText(mod);
		
		var desc = new FlxText(icon.x, icon.y
			+ icon.height
			+ 5, bg.width
			- (bgEllipse * 2),
			mod.description
			+ '\n\n'
			+ (count.length > 0 ? '($count)\n' : '')
			+ 'Version: '
			+ mod.modVersion);
		desc.setFormat('PhantomMuff 1.5', 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		
		if (mod.warnings.length > 0)
		{
			warningIcon = new FlxSprite(name.x + name.width + 5, name.y + (name.height / 2), Paths.getImage("menus/icons/warning"));
			warningIcon.y -= warningIcon.height / 2;
		}
		
		label.add(bg);
		label.add(icon);
		label.add(name);
		label.add(desc);
		if (warningIcon != null)
			label.add(warningIcon);
			
		setEmptyBackground();
	}
	
	function getCountText(mod:Mod)
	{
		var count = addCount('', mod.songCount, 'song');
		count = addCount(count, mod.characterCount, 'character');
		count = addCount(count, mod.noteskinCount, 'note skin');
		count = addCount(count, mod.judgementSkinCount, 'judgement skin');
		count = addCount(count, mod.splashSkinCount, 'splash skin');
		return count;
	}
	
	function addCount(text:String, count:Int, thing:String)
	{
		if (count <= 0)
			return text;
			
		if (text.length > 0)
			text += ', ';
		text += count;
		
		return text + ' ' + thing + (count > 1 ? 's' : '');
	}
}
