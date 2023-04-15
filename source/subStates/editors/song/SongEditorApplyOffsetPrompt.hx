package subStates.editors.song;

class SongEditorApplyOffsetPrompt extends PromptInputSubState
{
	public function new(?okCallback:String->Void)
	{
		super("Enter a value to apply an offset to all of your map's objects (notes, timing points, scroll velocities, etc.)", okCallback);
		inputText.filterMode = ONLY_NUMERIC;
	}
}
