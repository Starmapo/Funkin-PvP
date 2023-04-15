package subStates;

import ui.editors.EditorInputText;

class PromptInputSubState extends PromptSubState
{
	var inputText:EditorInputText;

	public function new(message:String, ?okCallback:String->Void, ?text:String)
	{
		super(message, [
			{
				name: 'OK',
				callback: function()
				{
					if (okCallback != null)
						okCallback(inputText.text);
				}
			},
			{
				name: 'Cancel'
			}
		]);

		inputText = new EditorInputText(promptBG.x + 5, promptText.y + promptText.height + 5, promptBG.width - 12, text, 16, true, camSubState);
		inputText.visible = false;
		add(inputText);

		var addY = inputText.height + 5;
		for (button in buttonGroup)
			button.y += addY;
		promptBG.resize(promptBG.width, promptBG.height + addY);
	}

	override function onOpen()
	{
		super.onOpen();
		inputText.visible = true;
	}

	override function onClose()
	{
		super.onClose();
		inputText.visible = false;
	}
}
