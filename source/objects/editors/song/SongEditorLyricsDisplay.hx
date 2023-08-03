package objects.editors.song;

import backend.editors.song.SongEditorActionManager;
import backend.structures.song.ITimingObject;
import backend.structures.song.LyricStep;
import objects.game.LyricsDisplay;
import states.editors.SongEditorState;

class SongEditorLyricsDisplay extends LyricsDisplay
{
	var state:SongEditorState;
	
	public function new(state:SongEditorState)
	{
		super(state.song, state.lyrics, 480);
		this.state = state;
		
		state.actionManager.onEvent.add(onEvent);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
	}
	
	function onEvent(type:String, params:Dynamic)
	{
		switch (type)
		{
			case SongEditorActionManager.ADD_OBJECT, SongEditorActionManager.REMOVE_OBJECT:
				// kinda sucks that i have to initialize everything again but oh well
				if (Std.isOfType(params.object, LyricStep))
					initialize();
			case SongEditorActionManager.ADD_OBJECT_BATCH, SongEditorActionManager.REMOVE_OBJECT_BATCH, SongEditorActionManager.MOVE_OBJECTS,
				SongEditorActionManager.RESNAP_OBJECTS:
				var batch:Array<ITimingObject> = params.objects;
				var hasLyric = false;
				for (obj in batch)
				{
					if (Std.isOfType(obj, LyricStep))
					{
						hasLyric = true;
						break;
					}
				}
				if (hasLyric)
					initialize();
		}
	}
}
