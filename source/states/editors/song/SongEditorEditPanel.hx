package states.editors.song;

import flixel.FlxG;
import util.editors.EditorInputText;

class SongEditorEditPanel extends EditorPanel
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Song',
				label: 'Song'
			}
		]);
		resize(250, 250);
		x = FlxG.width - width;
		screenCenter(Y);
		y -= 132;
		this.state = state;

		var songTab = createTab('Song');

		var titleInput = new EditorInputText(4, 4, 100, state.song.title);
		songTab.add(titleInput);

		addGroup(songTab);
	}
}
