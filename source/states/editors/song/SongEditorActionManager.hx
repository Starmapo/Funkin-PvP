package states.editors.song;

import util.editors.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}
}
