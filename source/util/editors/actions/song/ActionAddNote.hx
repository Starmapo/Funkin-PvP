package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;

class ActionAddNote implements IAction
{
	public var type:String = SongEditorActionManager.ADD_NOTE;

	var state:SongEditorState;
	var note:NoteInfo;

	public function new(state:SongEditorState, note:NoteInfo)
	{
		this.state = state;
		this.note = note;
	}

	public function perform()
	{
		state.song.notes.push(note);
		state.song.sort();
		state.actionManager.triggerEvent(type, {
			note: note
		});
	}

	public function undo()
	{
		new ActionRemoveNote(state, note).perform();
	}
}
