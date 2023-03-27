package util.editors.actions.song;

import states.editors.SongEditorState;

class ActionChangeDifficultyName implements IAction
{
	public var type:String = SongEditorActionManager.CHANGE_DIFFICULTY_NAME;

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
		state.song.difficultyName = value;
		triggerEvent();
	}

	public function undo()
	{
		state.song.difficultyName = lastValue;
		triggerEvent();
	}

	function triggerEvent()
	{
		state.actionManager.triggerEvent(type, {difficultyName: state.song.difficultyName});
	}
}
