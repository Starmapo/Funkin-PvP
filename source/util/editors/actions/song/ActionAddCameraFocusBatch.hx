package util.editors.actions.song;

import data.song.CameraFocus;
import states.editors.SongEditorState;

class ActionAddCameraFocusBatch implements IAction
{
	public var type:String = SongEditorActionManager.ADD_CAMERA_FOCUS_BATCH;

	var state:SongEditorState;
	var camFocuses:Array<CameraFocus>;

	public function new(state:SongEditorState, camFocuses:Array<CameraFocus>)
	{
		this.state = state;
		this.camFocuses = camFocuses;
	}

	public function perform()
	{
		for (cameraFocus in camFocuses)
			state.song.cameraFocuses.push(cameraFocus);
		state.song.sort();
		state.actionManager.triggerEvent(type, {camFocuses: camFocuses});
	}

	public function undo()
	{
		new ActionRemoveCameraFocusBatch(state, camFocuses).perform();
	}
}
