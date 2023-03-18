package states.editors.song;

import flixel.addons.ui.FlxUIRadioGroup;
import flixel.util.FlxColor;
import states.editors.song.SongEditorState.CompositionTool;

class SongEditorCompositionPanel extends EditorPanel
{
	public var tools:FlxUIRadioGroup;

	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Composition',
				label: 'Composition'
			}
		]);
		resize(250, 95);
		x = 10;
		screenCenter(Y);
		y += 132;
		this.state = state;

		var tab = createTab('Composition');

		var toolNames = [CompositionTool.SELECT, CompositionTool.NOTE, CompositionTool.LONG_NOTE];
		tools = new FlxUIRadioGroup(4, 4, toolNames, toolNames, function(id)
		{
			state.currentTool = id;
		});
		@:privateAccess {
			for (radio in tools._list_radios)
			{
				radio.button.label.setBorderStyle(OUTLINE, FlxColor.BLACK);
			}
		}
		tab.add(tools);

		addGroup(tab);
	}
}
