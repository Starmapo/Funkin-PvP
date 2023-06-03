package ui.editors.char;

import data.char.CharacterInfo.AnimInfo;
import flixel.addons.ui.FlxUIButton;
import flixel.graphics.frames.FlxFramesCollection;
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
		resize(230, 50);
		setPosition(10, 100);
		this.state = state;

		var tab = createTab('Animation Select');

		var spacing = 4;

		animDropdown = new EditorDropdownMenu(4, 4, [], function(anim)
		{
			state.changeAnim(anim);
		}, this);
		reloadDropdown();

		var addButton = new FlxUIButton(animDropdown.x + animDropdown.width + spacing, animDropdown.y, 'Add', function()
		{
			var name = 'newAnim';
			var i = 1;
			while (state.char.animation.exists(name))
			{
				name = 'newAnim$i';
				i++;
			}

			var atlasName = FlxFramesCollection.getAtlasName(state.char.frames.frames[0].name, state.char.frames.atlasType);
			var anim = new AnimInfo({
				name: name,
				atlasName: atlasName
			});
			state.actionManager.perform(new ActionAddAnim(state, anim));
			state.changeAnim(name);
		});
		addButton.resize(30, addButton.height);
		addButton.autoCenterLabel();
		tab.add(addButton);

		var removeButton = new FlxUIButton(addButton.x + addButton.width + spacing, addButton.y, 'Remove', function()
		{
			var anim = state.char.getCurAnim();
			if (anim != null)
				state.actionManager.perform(new ActionRemoveAnim(state, anim));
		});
		removeButton.resize(60, removeButton.height);
		removeButton.autoCenterLabel();
		tab.add(removeButton);

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
			case CharacterEditorActionManager.ADD_ANIM, CharacterEditorActionManager.REMOVE_ANIM, CharacterEditorActionManager.CHANGE_ANIM_NAME:
				reloadDropdown();
		}
	}
}