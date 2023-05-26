package subStates.editors.song;

import flixel.FlxG;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import ui.editors.EditorInputText;

class SongEditorChangeNoteTypePrompt extends PromptInputSubState
{
	var typeInputText:EditorInputText;
	var paramsInputText:EditorInputText;

	public function new(?okCallback:String->String->String->Void)
	{
		super("Enter a note type to change to a different type.");

		var typeText = new FlxUIText(0, inputText.y + inputText.height + 5, FlxG.width / 2, "New note type:");
		typeText.setFormat(null, 8, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		typeText.screenCenter(X);
		add(typeText);

		typeInputText = new EditorInputText(promptBG.x + 5, typeText.y + typeText.height + 5, promptBG.width - 12, '', 16, true, camSubState);
		typeInputText.visible = false;
		add(typeInputText);

		var paramsText = new FlxUIText(0, typeInputText.y + typeInputText.height + 5, FlxG.width / 2, "New parameters (leave blank to not replace):");
		paramsText.setFormat(null, 8, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		paramsText.screenCenter(X);
		add(paramsText);

		paramsInputText = new EditorInputText(promptBG.x + 5, paramsText.y + paramsText.height + 5, promptBG.width - 12, '', 16, true, camSubState);
		paramsInputText.visible = false;
		add(paramsInputText);

		buttons[0].callback = function()
		{
			if (okCallback != null)
				okCallback(inputText.text, typeInputText.text, paramsInputText.text);
		}

		var addY = typeText.height + typeInputText.height + paramsText.height + paramsInputText.height + 20;
		for (button in buttonGroup)
			button.y += addY;
		promptBG.resize(promptBG.width, promptBG.height + addY);
	}

	override function onOpen()
	{
		super.onOpen();
		typeInputText.visible = paramsInputText.visible = true;
	}

	override function onClose()
	{
		super.onClose();
		typeInputText.visible = paramsInputText.visible = false;
	}
}
