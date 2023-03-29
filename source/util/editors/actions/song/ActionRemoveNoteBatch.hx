package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;

class ActionRemoveNoteBatch implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_NOTE_BATCH;

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
		{
			state.song.notes.remove(note);
			state.selectedNotes.remove(note);
		}
		state.song.sort();
		state.actionManager.triggerEvent(type, {notes: notes});
	}

	public function undo()
	{
		new ActionAddNoteBatch(state, notes).perform();
	}
}
