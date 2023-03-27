package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeSource implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_SOURCE;

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
		state.song.source = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.source = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {source: state.song.source});
	}
}
