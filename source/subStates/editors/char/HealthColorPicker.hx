package subStates.editors.char;

import flixel.addons.ui.FlxUIButton;
import flixel.util.FlxColor;
import states.editors.CharacterEditorState;

class HealthColorPicker extends ColorPickerSubState
{
	var state:CharacterEditorState;
	
	public function new(state:CharacterEditorState, startingColor:FlxColor, ?callback:FlxColor->Void)
	{
		super(startingColor, callback);
		this.state = state;
	}
	
	override function create()
	{
		super.create();
		
		var getIconColorButton = new FlxUIButton(uiTabs.width - 10, 50, 'Get Icon Color', function()
		{
			var daColor = CoolUtil.getDominantColor(state.healthBar.icon);
			daColor.alpha = 255;
			color = daColor;
			updateColor();
		});
		getIconColorButton.resize(120, getIconColorButton.height);
		getIconColorButton.x -= getIconColorButton.width;
		tab.add(getIconColorButton);
	}
}
