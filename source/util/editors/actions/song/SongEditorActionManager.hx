package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;
import util.editors.actions.ActionManager;

class SongEditorActionManager extends ActionManager
{
	public static inline var PLACE_NOTE:String = 'place-note';
	public static inline var REMOVE_NOTE:String = 'remove-note';
	public static inline var PLACE_NOTE_BATCH:String = 'place-note-batch';
	public static inline var REMOVE_NOTE_BATCH:String = 'remove-note-batch';
	public static inline var RESNAP_NOTES:String = 'resnap-notes';

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
}
