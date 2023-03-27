package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeInitialSV implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_INITIAL_SV;

	var state:SongEditorState;
	var value:Float;
	var lastValue:Float;

	public function new(state:SongEditorState, value:Float, lastValue:Float)
	{
		this.state = state;
		this.value = value;
		this.lastValue = lastValue;
	}

	public function perform()
	{
		state.song.initialScrollVelocity = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.initialScrollVelocity = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {initialScrollVelocity: state.song.initialScrollVelocity});
	}
}
