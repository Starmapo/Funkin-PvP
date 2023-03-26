package util.editors.actions.song;

import data.song.SliderVelocity;
import states.editors.SongEditorState;

class ActionRemoveScrollVelocity implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_SCROLL_VELOCITY;

	var state:SongEditorState;
	var scrollVelocity:SliderVelocity;

	public function new(state:SongEditorState, scrollVelocity:SliderVelocity)
	{
		this.state = state;
		this.scrollVelocity = scrollVelocity;
	}

	public function perform()
	{
		state.song.sliderVelocities.remove(scrollVelocity);
		state.actionManager.triggerEvent(type, {scrollVelocity: scrollVelocity});
	}

	public function undo()
	{
		new ActionAddScrollVelocity(state, scrollVelocity).perform();
	}
}
