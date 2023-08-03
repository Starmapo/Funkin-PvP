package states;

import flixel.FlxG;
import flixel.util.FlxColor;
import objects.editors.EditorInputText;

class TestState extends FNFState
{
	override function create()
	{
		transIn = transOut = null;
		
		FlxG.camera.bgColor = FlxColor.GRAY;
		
		var inputText = new EditorInputText();
		inputText.textField.textField.autoSize = NONE;
		inputText.textField.textField.multiline = true;
		inputText.textField.textField.wordWrap = true;
		inputText.resize(200, 200);
		add(inputText);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
}
