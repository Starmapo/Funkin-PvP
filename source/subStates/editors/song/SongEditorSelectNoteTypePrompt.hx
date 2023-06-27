package subStates.editors.song;

class SongEditorSelectNoteTypePrompt extends PromptInputSubState
{
	public function new(?okCallback:String->Void)
	{
		super("Enter a note type to select.", okCallback);
	}
}
