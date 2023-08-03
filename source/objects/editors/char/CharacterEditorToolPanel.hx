package objects.editors.char;

import flixel.FlxG;
import states.editors.CharacterEditorState;

class CharacterEditorToolPanel extends EditorPanel
{
	public var tools:EditorRadioGroup;
	
	var state:CharacterEditorState;
	
	public function new(state:CharacterEditorState)
	{
		super([
			{
				name: 'Move Tool',
				label: 'Move Tool'
			}
		]);
		resize(250, 60);
		setPosition(10, FlxG.height - height - 10);
		this.state = state;
		
		var tab = createTab('Move Tool');
		
		var toolNames = [MoveTool.ANIM, MoveTool.POSITION];
		tools = new EditorRadioGroup(4, 4, toolNames, toolNames, function(id)
		{
			state.currentTool.value = id;
		});
		tools.selectedId = state.currentTool.value;
		tab.add(tools);
		
		addGroup(tab);
		
		state.currentTool.valueChanged.add(onToolChanged);
	}
	
	override function destroy()
	{
		super.destroy();
		state = null;
		tools = null;
	}
	
	function onToolChanged(value:MoveTool, lastValue:MoveTool)
	{
		if (tools.selectedId != value)
			tools.selectedId = value;
	}
}
