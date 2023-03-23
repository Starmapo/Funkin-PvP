package states.editors.song;

import flixel.addons.ui.FlxUIRadioGroup;
import states.editors.song.SongEditorState.CompositionTool;
import ui.editors.EditorRadioGroup;

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
		tools = new EditorRadioGroup(4, 4, toolNames, function(id)
		{
			state.currentTool = id;
		}, 50);
		tab.add(tools);

		addGroup(tab);
	}
}
