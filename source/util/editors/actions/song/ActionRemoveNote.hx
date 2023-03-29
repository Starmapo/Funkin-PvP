package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;

class ActionRemoveNote implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;

	public function new(state:SongEditorState, note:NoteInfo)
	{
		this.state = state;
		this.note = note;
	}

	public function perform()
	{
		state.song.notes.remove(note);
		state.song.sort();
		state.selectedNotes.remove(note);
		state.actionManager.triggerEvent(type, {
			note: note
		});
	}

	public function undo()
	{
		new ActionAddNote(state, note).perform();
	}
}
