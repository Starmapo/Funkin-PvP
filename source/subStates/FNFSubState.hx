package subStates;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import ui.editors.EditorInputText;

class FNFSubState extends FlxSubState
{
	public var dropdowns:Array<FlxUIDropDownMenu> = [];
	public var inputTexts:Array<EditorInputText> = [];
	
	var checkObjects:Bool = false;
	var camSubState:FlxCamera;
	
	public function new()
	{
		super();
		memberAdded.add(onMemberAdded);
		openCallback = onOpen;
		closeCallback = onClose;
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
	
	override function destroy()
	{
		super.destroy();
		dropdowns = null;
		inputTexts = null;
		if (camSubState != null && FlxG.cameras.list.contains(camSubState))
			FlxG.cameras.remove(camSubState);
		camSubState = null;
	}
	
	function onOpen()
	{
		if (camSubState != null)
			camSubState.visible = true;
		for (text in inputTexts)
			text.visible = true;
	}
	
	function onClose()
	{
		if (camSubState != null)
			camSubState.visible = false;
		for (text in inputTexts)
			text.visible = false;
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
	
	function createCamera(?bgColor:FlxColor)
	{
		if (camSubState != null)
			return;
		if (bgColor == null)
			bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.6);
			
		camSubState = new FlxCamera();
		camSubState.bgColor = bgColor;
		camSubState.visible = false;
		FlxG.cameras.add(camSubState, false);
		cameras = [camSubState];
	}
}
