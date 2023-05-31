package ui.editors.char;

import states.editors.CharacterEditorState;
import util.editors.char.CharacterEditorActionManager;

class CharacterEditorAnimPanel extends EditorPanel
{
	var state:CharacterEditorState;

	public var animDropdown:EditorDropdownMenu;

	public function new(state:CharacterEditorState)
	{
		super([
			{
				name: 'Animation Select',
				label: 'Animation Select'
			}
		]);
		resize(130, 50);
		setPosition(10, 100);
		this.state = state;

		var tab = createTab('Animation Select');

		animDropdown = new EditorDropdownMenu(4, 4, [], function(anim)
		{
			state.changeAnim(anim);
		}, this);
		reloadDropdown();

		tab.add(animDropdown);

		addGroup(tab);

		state.actionManager.onEvent.add(onEvent);
	}

	public function reloadDropdown()
	{
		state.charInfo.sortAnims();

		var anims:Array<String> = [];
		for (anim in state.charInfo.anims)
			anims.push(anim.name);

		animDropdown.setData(EditorDropdownMenu.makeStrIdLabelArray(anims));
		animDropdown.selectedLabel = state.char.animation.name;
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		animDropdown = null;
	}

	function onEvent(event:String, params:Dynamic)
	{
		switch (event)
		{
			case CharacterEditorActionManager.CHANGE_ANIM_NAME:
				reloadDropdown();
		}
	}
}
