package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;
import util.editors.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	public static inline var PLACE_NOTE:String = 'place-note';
	public static inline var REMOVE_NOTE:String = 'remove-note';

	var state:SongEditorState;

	public function new(state:SongEditorState)
	{
		this.state = state;
	}

	public function placeNote(lane:Int, startTime:Int, endTime:Int = 0, type:String = '', params:String = '')
	{
		var note = new NoteInfo({
			startTime: startTime,
			lane: lane,
			endTime: endTime,
			type: type,
			params: params
		});
		perform(new ActionPlaceNote(state, note));
		return note;
	}

	public function placeNoteInfo(note:NoteInfo)
	{
		perform(new ActionPlaceNote(state, note));
	}

	public function removeNote(note:NoteInfo)
	{
		perform(new ActionRemoveNote(state, note));
	}
}
