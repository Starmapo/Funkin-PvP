package states;

import data.char.CharacterInfo;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxTimer;
import sprites.game.Character;

class FNFState extends FlxTransitionableState
{
	public var dropdowns:Array<FlxUIDropDownMenu> = [];

	var cachedGraphics:Array<FlxGraphic> = [];
	var cachedCharacters:Array<String> = [];
	var checkDropdowns:Bool = false;

	public function new()
	{
		super();
		memberAdded.add(onMemberAdded);
	}

	public function checkAllowInput()
	{
		if (FlxG.stage.focus != null)
			return false;

		for (dropdown in dropdowns)
		{
			if (dropdown.dropPanel.visible)
				return false;
		}

		return true;
	}

	public function precacheGraphic(graphic:FlxGraphicAsset)
	{
		if (graphic == null)
			return null;

		var graphic = FlxG.bitmap.add(graphic);
		if (graphic == null || cachedGraphics.contains(graphic))
			return null;

		var spr = new FlxSprite(0, 0, graphic);
		spr.visible = false;
		spr.scrollFactor.set();
		add(spr);
		new FlxTimer().start(1, function(_)
		{
			remove(spr, true);
			spr.destroy();
		});
		cachedGraphics.push(graphic);
		return spr;
	}

	public function precacheImage(image:String)
	{
		return precacheGraphic(Paths.getImage(image));
	}

	public function precacheCharacter(char:String)
	{
		if (char == null || char.length < 1 || cachedCharacters.contains(char))
			return null;

		var spr = new Character(0, 0, CharacterInfo.loadCharacterFromName(char));
		if (spr.graphic != null)
			spr.graphic.destroyOnNoUse = false;
		else
			return null;

		spr.visible = false;
		spr.scrollFactor.set();
		add(spr);
		new FlxTimer().start(1, function(_)
		{
			remove(spr, true);
			spr.destroy();
		});
		cachedCharacters.push(char);

		return spr;
	}

	override function destroy()
	{
		super.destroy();
		dropdowns = null;
		cachedGraphics = null;
		cachedCharacters = null;
	}

	function onMemberAdded(obj:FlxBasic)
	{
		if (checkDropdowns)
			checkDropdown(obj);
	}

	function checkDropdown(obj:FlxBasic)
	{
		if (Std.isOfType(obj, FlxTypedGroup))
		{
			var group:FlxGroup = cast obj;
			for (obj in group)
				checkDropdown(obj);
		}
		else if (Std.isOfType(obj, FlxTypedSpriteGroup))
		{
			var group:FlxSpriteGroup = cast obj;
			for (obj in group)
				checkDropdown(obj);
		}
		else if (Std.isOfType(obj, FlxUIDropDownMenu))
		{
			var dropdown:FlxUIDropDownMenu = cast obj;
			dropdowns.push(dropdown);
			trace('found dropdown yippee!');
		}
	}
}
