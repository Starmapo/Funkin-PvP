package backend;

import backend.structures.char.CharacterInfo;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import objects.editors.EditorInputText;
import objects.game.Character;

class FNFState extends FlxTransitionableState
{
	public var dropdowns:Array<FlxUIDropDownMenu> = [];
	public var inputTexts:Array<EditorInputText> = [];
	
	var checkObjects:Bool = false;
	var cachedGraphics:Array<FlxGraphic> = [];
	var cachedCharacters:Array<String> = [];
	
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
			if (dropdown.dropPanel.exists)
				return false;
		}
		
		return true;
	}
	
	public function precacheGraphic(graphic:FlxGraphic)
	{
		if (graphic == null || cachedGraphics.contains(graphic))
			return null;
			
		graphic.destroyOnNoUse = false;
		var spr = new FlxSprite(0, 0, graphic);
		spr.alpha = 0.00001;
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
	
	public function precacheImage(image:String, ?mod:String)
	{
		return precacheGraphic(Paths.getImage(image, mod));
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
			
		spr.alpha = 0.00001;
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
		inputTexts = null;
		cachedGraphics = null;
		cachedCharacters = null;
	}
	
	function onMemberAdded(obj:FlxBasic)
	{
		if (checkObjects)
			check(obj);
	}
	
	function check(obj:FlxBasic)
	{
		if (Std.isOfType(obj, FlxUIDropDownMenu))
		{
			var dropdown:FlxUIDropDownMenu = cast obj;
			dropdowns.push(dropdown);
		}
		else if (Std.isOfType(obj, EditorInputText))
		{
			var inputText:EditorInputText = cast obj;
			inputTexts.push(inputText);
		}
		else if (Std.isOfType(obj, FlxTypedGroup))
		{
			var group:FlxTypedGroup<Dynamic> = cast obj;
			for (obj in group)
				check(obj);
		}
		else if (Std.isOfType(obj, FlxTypedSpriteGroup))
		{
			var group:FlxTypedSpriteGroup<Dynamic> = cast obj;
			for (obj in group.group)
				check(obj);
		}
	}
}
