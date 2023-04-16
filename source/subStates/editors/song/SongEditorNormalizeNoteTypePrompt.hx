package subStates.editors.song;

class SongEditorNormalizeNoteTypePrompt extends PromptInputSubState
{
	public function new(?okCallback:String->Void)
	{
		super("Enter a note type to normalize (change to default notes).", okCallback);
	}
}