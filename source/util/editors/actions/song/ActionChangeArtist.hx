package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeArtist implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_ARTIST;

	var state:SongEditorState;
	var value:String;
	var lastValue:String;

	public function new(state:SongEditorState, value:String, lastValue:String)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.artist = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.artist = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {artist: state.song.artist});
	}
}
