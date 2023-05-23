package states;

import data.char.CharacterInfo;
import sprites.game.Character;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxTimer;
import ui.editors.EditorDropdownMenu;

class FNFState extends FlxTransitionableState
{
	public var dropdowns:Array<EditorDropdownMenu> = [];

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

		var spr = new FlxSprite(0, 0, graphic);
		spr.visible = false;
		spr.scrollFactor.set();
		add(spr);
		new FlxTimer().start(1, function(_)
		{
			remove(spr, true);
			spr.destroy();
		});
		return spr;
	}

	public function precacheImage(image:String)
	{
		return precacheGraphic(Paths.getImage(image));
	}

	public function precacheCharacter(char:String)
	{
		if (char == null || char.length < 1)
			return null;

		var spr = new Character(0, 0, CharacterInfo.loadCharacterFromName(char));
		if (spr.graphic != null)
			spr.graphic.destroyOnNoUse = false;
		spr.visible = false;
		spr.scrollFactor.set();
		add(spr);
		new FlxTimer().start(1, function(_)
		{
			remove(spr, true);
			spr.destroy();
		});

		return spr;
	}

	override function destroy()
	{
		super.destroy();
		dropdowns = null;
	}

	function onMemberAdded(object:FlxBasic) {}
}
