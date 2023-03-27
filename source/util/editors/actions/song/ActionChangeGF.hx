package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeGF implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_GF;

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
		state.song.gf = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.gf = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {gf: state.song.gf});
	}
}
