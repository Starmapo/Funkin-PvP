package subStates.editors.song;

import backend.subStates.PromptInputSubState;

class SongEditorSelectNoteTypePrompt extends PromptInputSubState
{
	public function new(?okCallback:String->Void)
	{
		super("Enter a note type to select.", okCallback);
	}
}
