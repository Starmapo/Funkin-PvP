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
	public static inline var FLIP_NOTES:String = 'flip-notes';
	public static inline var ADD_SCROLL_VELOCITY:String = 'add-sv';
	public static inline var REMOVE_SCROLL_VELOCITY:String = 'remove-sv';
	public static inline var ADD_TIMING_POINT:String = 'add-point';
	public static inline var REMOVE_TIMING_POINT:String = 'remove-point';
	public static inline var CHANGE_TITLE:String = 'change-title';
	public static inline var CHANGE_ARTIST:String = 'change-artist';
	public static inline var CHANGE_SOURCE:String = 'change-source';
	public static inline var CHANGE_DIFFICULTY_NAME:String = 'change-difficulty-name';
	public static inline var CHANGE_OPPONENT:String = 'change-opponent';
	public static inline var CHANGE_BF:String = 'change-bf';
	public static inline var CHANGE_GF:String = 'change-gf';
	public static inline var CHANGE_INITIAL_SV:String = 'change-initial-sv';

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
