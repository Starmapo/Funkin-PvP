package util.editors.actions.song;

import data.song.CameraFocus;
import states.editors.SongEditorState;

class ActionAddCameraFocus implements IAction
{
	public var type:String = SongEditorActionManager.ADD_CAMERA_FOCUS;

	var state:SongEditorState;
	var camFocus:CameraFocus;

	public function new(state:SongEditorState, camFocus:CameraFocus)
	{
		this.state = state;
		this.camFocus = camFocus;
	}

	public function perform()
	{
		state.song.cameraFocuses.push(camFocus);
		state.song.sort();
		state.actionManager.triggerEvent(type, {camFocus: camFocus});
	}

	public function undo()
	{
		new ActionRemoveCameraFocus(state, camFocus).perform();
	}
}
