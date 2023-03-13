package states.editors.song;

import util.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}
}
