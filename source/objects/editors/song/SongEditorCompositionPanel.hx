package objects.editors.song;

import flixel.addons.ui.FlxUIRadioGroup;
import objects.editors.EditorPanel;
import objects.editors.EditorRadioGroup;
import states.editors.SongEditorState;

class SongEditorCompositionPanel extends EditorPanel
{
	public var tools:FlxUIRadioGroup;
	
	var state:SongEditorState;
	
	public function new(state:SongEditorState)
	{
		super([
			{
				name: 'Composition',
				label: 'Composition'
			}
		]);
		resize(250, 75);
		x = 10;
		screenCenter(Y);
		y += 132;
		this.state = state;
		
		var tab = createTab('Composition');
		
		var toolNames = [CompositionTool.SELECT, CompositionTool.OBJECT, CompositionTool.LONG_NOTE];
		tools = new EditorRadioGroup(4, 4, toolNames, toolNames, function(id)
		{
			state.currentTool.value = id;
		});
		tools.selectedId = state.currentTool.value;
		tab.add(tools);
		
		addGroup(tab);
	}
	
	override function destroy()
	{
		super.destroy();
		tools = null;
		state = null;
	}
}
