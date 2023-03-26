package util.editors.actions.song;

import data.song.NoteInfo;
import states.editors.SongEditorState;

class ActionFlipNotes implements IAction
{
	public var type:String = SongEditorActionManager.FLIP_NOTES;

	var state:SongEditorState;
	var notes:Array<NoteInfo>;
	var fullFlip:Bool;

	public function new(state:SongEditorState, notes:Array<NoteInfo>, fullFlip:Bool)
	{
		this.state = state;
		this.notes = notes;
		this.fullFlip = fullFlip;
	}

	public function perform()
	{
		for (note in notes)
		{
			if (fullFlip)
				note.lane = 7 - note.lane;
			else
			{
				if (note.lane >= 4)
				{
					note.lane = 7 - (note.lane - 4);
				}
				else
				{
					note.lane = 3 - note.lane;
				}
			}
		}

		state.actionManager.triggerEvent(type, {
			notes: notes
		});
	}

	public function undo()
	{
		perform();
	}
}
