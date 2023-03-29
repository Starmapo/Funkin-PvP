package util.editors.actions.song;

import data.song.CameraFocus;
import data.song.TimingPoint;
import states.editors.SongEditorState;

class ActionRemoveCameraFocus implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_CAMERA_FOCUS;

	var state:SongEditorState;
	var camFocus:CameraFocus;

	public function new(state:SongEditorState, camFocus:CameraFocus)
	{
		this.state = state;
		this.camFocus = camFocus;
	}

	public function perform()
	{
		state.song.cameraFocuses.remove(camFocus);
		state.actionManager.triggerEvent(type, {camFocus: camFocus});
	}

	public function undo()
	{
		new ActionAddCameraFocus(state, camFocus).perform();
	}
}
