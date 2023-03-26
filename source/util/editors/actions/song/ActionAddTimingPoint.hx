package util.editors.actions.song;

import data.song.TimingPoint;
import states.editors.SongEditorState;

class ActionAddTimingPoint implements IAction
{
	public var type:String = SongEditorActionManager.ADD_TIMING_POINT;

	var state:SongEditorState;
	var timingPoint:TimingPoint;

	public function new(state:SongEditorState, timingPoint:TimingPoint)
	{
		this.state = state;
		this.timingPoint = timingPoint;
	}

	public function perform()
	{
		state.song.timingPoints.push(timingPoint);
		state.song.sort();
		state.actionManager.triggerEvent(type, {timingPoint: timingPoint});
	}

	public function undo()
	{
		new ActionRemoveTimingPoint(state, timingPoint).perform();
	}
}
