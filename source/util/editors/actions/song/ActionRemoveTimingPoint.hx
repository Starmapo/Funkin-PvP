package util.editors.actions.song;

import data.song.TimingPoint;
import states.editors.SongEditorState;

class ActionRemoveTimingPoint implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_TIMING_POINT;

	var state:SongEditorState;
	var timingPoint:TimingPoint;

	public function new(state:SongEditorState, timingPoint:TimingPoint)
	{
		this.state = state;
		this.timingPoint = timingPoint;
	}

	public function perform()
	{
		state.song.timingPoints.remove(timingPoint);
		state.actionManager.triggerEvent(type, {timingPoint: timingPoint});
	}

	public function undo()
	{
		new ActionAddTimingPoint(state, timingPoint).perform();
	}
}
