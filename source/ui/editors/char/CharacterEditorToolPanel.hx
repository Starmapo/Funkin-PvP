package ui.editors.char;

import flixel.FlxG;
import states.editors.CharacterEditorState;

class CharacterEditorToolPanel extends EditorPanel
{
	var state:CharacterEditorState;

	public function new(state:CharacterEditorState)
	{
		super([
			{
				name: 'Move Tool',
				label: 'Move Tool'
			}
		]);
		resize(250, 60);
		setPosition(10, FlxG.height - height - 10);
		this.state = state;

		var tab = createTab('Move Tool');

		var toolNames = [MoveTool.ANIM, MoveTool.POSITION];
		var tools = new EditorRadioGroup(4, 4, toolNames, toolNames, function(id)
		{
			state.currentTool.value = id;
		});
		tools.selectedId = state.currentTool.value;
		tab.add(tools);

		addGroup(tab);
	}
}
