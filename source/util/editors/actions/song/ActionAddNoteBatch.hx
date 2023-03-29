package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;

class ActionAddNoteBatch implements IAction
{
	public var type:String = SongEditorActionManager.ADD_NOTE_BATCH;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;

	public function new(state:SongEditorState, notes:Array<NoteInfo>)
	{
		this.state = state;
		this.notes = notes;
	}

	public function perform()
	{
		for (note in notes)
			state.song.notes.push(note);
		state.song.sort();
		state.actionManager.triggerEvent(type, {notes: notes});
	}

	public function undo()
	{
		new ActionRemoveNoteBatch(state, notes).perform();
	}
}
