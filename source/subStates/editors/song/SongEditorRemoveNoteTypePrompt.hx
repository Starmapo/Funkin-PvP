package subStates.editors.song;

class SongEditorRemoveNoteTypePrompt extends PromptInputSubState
{
	public function new(?okCallback:String->Void)
	{
		super("Enter a note type to remove.", okCallback);
	}
}
