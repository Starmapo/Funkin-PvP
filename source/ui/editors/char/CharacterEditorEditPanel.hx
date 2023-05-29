package ui.editors.char;

import flixel.FlxG;
import states.editors.CharacterEditorState;

class CharacterEditorEditPanel extends EditorPanel
{
	var state:CharacterEditorState;

	public function new(state:CharacterEditorState)
	{
		super([
			{
				name: 'Animation',
				label: 'Animation'
			},
			{
				name: 'Character',
				label: 'Character'
			}
		]);
		resize(390, 250);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		this.state = state;

		createAnimationTab();
		createCharacterTab();

		selected_tab_id = 'Character';
	}

	function createAnimationTab()
	{
		var tab = createTab('Animation');

		addGroup(tab);
	}

	function createCharacterTab()
	{
		var tab = createTab('Character');

		addGroup(tab);
	}
}
