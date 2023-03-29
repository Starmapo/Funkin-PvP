package util.editors.actions.song;

import data.song.CameraFocus;
import states.editors.SongEditorState;

class ActionRemoveCameraFocusBatch implements IAction
{
	public var type:String = SongEditorActionManager.REMOVE_CAMERA_FOCUS_BATCH;

	var state:SongEditorState;
	var camFocuses:Array<CameraFocus>;

	public function new(state:SongEditorState, camFocuses:Array<CameraFocus>)
	{
		this.state = state;
		this.camFocuses = camFocuses;
	}

	public function perform()
	{
		for (camFocus in camFocuses)
			state.song.cameraFocuses.remove(camFocus);
		state.actionManager.triggerEvent(type, {camFocuses: camFocuses});
	}

	public function undo()
	{
		new ActionAddCameraFocusBatch(state, camFocuses).perform();
	}
}
