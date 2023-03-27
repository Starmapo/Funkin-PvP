package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeTitle implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_TITLE;

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
		state.song.title = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.title = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {title: state.song.title});
	}
}
