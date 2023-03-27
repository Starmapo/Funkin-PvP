package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeOpponent implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_OPPONENT;

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
		state.song.opponent = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.opponent = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {opponent: state.song.opponent});
	}
}
