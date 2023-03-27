package subStates.editors.song;

import states.editors.SongEditorState;

class SongEditorSavePrompt extends PromptSubState
{
	var callback:String->Void;

	public function new(state:SongEditorState, ?callback:String->Void)
	{
		super('You have unsaved changes. Would you like to save your chart?', [
			{
				name: 'Yes',
				callback: function()
				{
					if (callback != null)
						callback('Yes');
				}
			},
			{
				name: 'No',
				callback: function()
				{
					if (callback != null)
						callback('No');
				}
			},
			{
				name: 'Cancel',
				callback: function()
				{
					if (callback != null)
						callback('Cancel');
				}
			}
		]);
		this.callback = callback;
	}
}
