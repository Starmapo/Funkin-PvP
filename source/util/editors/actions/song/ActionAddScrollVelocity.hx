package util.editors.actions.song;

import data.song.SliderVelocity;
import states.editors.SongEditorState;

class ActionAddScrollVelocity implements IAction
{
	public var type:String = SongEditorActionManager.ADD_SCROLL_VELOCITY;

	var state:SongEditorState;
	var scrollVelocity:SliderVelocity;

	public function new(state:SongEditorState, scrollVelocity:SliderVelocity)
	{
		this.state = state;
		this.scrollVelocity = scrollVelocity;
	}

	public function perform()
	{
		state.song.sliderVelocities.push(scrollVelocity);
		state.song.sort();
		state.actionManager.triggerEvent(type, {scrollVelocity: scrollVelocity});
	}

	public function undo()
	{
		new ActionRemoveScrollVelocity(state, scrollVelocity).perform();
	}
}
