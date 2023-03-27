package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeBF implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_BF;

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
		state.song.bf = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.bf = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {bf: state.song.bf});
	}
}
