package ui.editors.char;

import data.char.CharacterInfo.AnimInfo;
import flixel.FlxG;
import states.editors.CharacterEditorState;
import util.editors.char.CharacterEditorActionManager;

class CharacterEditorEditPanel extends EditorPanel
{
	var state:CharacterEditorState;
	var nameInput:EditorInputText;
	var atlasNameInput:EditorInputText;
	var curAnim:AnimInfo;
	var spacing:Int = 4;

	public function new(state:CharacterEditorState)
	{
		super([
			{
				name: 'Animation',
				label: 'Animation'
			},
			{
				name: 'Character',
				label: 'Character'
			}
		]);
		resize(390, 250);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		this.state = state;

		createAnimationTab();
		createCharacterTab();

		updateCurAnim();

		selected_tab_id = 'Character';

		state.actionManager.onEvent.add(onEvent);
	}

	public function updateCurAnim()
	{
		curAnim = state.char.getCurAnim();
		updateName();
		updateAtlasName();
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		nameInput = null;
		atlasNameInput = null;
		curAnim = null;
	}

	function createAnimationTab()
	{
		var tab = createTab('Animation');

		var inputSpacing = 125;
		var inputWidth = 250;

		var nameLabel = new EditorText(4, 5, 0, 'Name:');
		tab.add(nameLabel);

		nameInput = new EditorInputText(nameLabel.x + inputSpacing, 4, inputWidth);
		nameInput.textChanged.add(function(text, lastText)
		{
			if (text.length < 1)
			{
				nameInput.text = lastText;
				state.notificationManager.showNotification("You can't have an empty animation name!", ERROR);
				return;
			}
			for (anim in state.charInfo.anims)
			{
				if (anim.name == text)
				{
					nameInput.text = lastText;
					state.notificationManager.showNotification("There's already an animation named \"" + text + "\"!", ERROR);
					return;
				}
			}
			state.actionManager.perform(new ActionChangeAnimName(state, curAnim, text));
		});
		tab.add(nameInput);

		var atlasNameLabel = new EditorText(nameLabel.x, nameLabel.y + nameLabel.height + spacing, 0, 'Atlas Name:');
		tab.add(atlasNameLabel);

		atlasNameInput = new EditorInputText(atlasNameLabel.x + inputSpacing, atlasNameLabel.y - 1, inputWidth);
		atlasNameInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeAnimAtlasName(state, curAnim, text));
		});
		tab.add(atlasNameInput);

		addGroup(tab);
	}

	function createCharacterTab()
	{
		var tab = createTab('Character');

		addGroup(tab);
	}

	function updateName()
	{
		nameInput.text = curAnim != null ? curAnim.name : '';
	}

	function updateAtlasName()
	{
		atlasNameInput.text = curAnim != null ? curAnim.atlasName : '';
	}

	function onEvent(event:String, params:Dynamic)
	{
		switch (event)
		{
			case CharacterEditorActionManager.CHANGE_ANIM_NAME:
				if (curAnim == params.anim)
					updateName();
			case CharacterEditorActionManager.CHANGE_ANIM_ATLAS_NAME:
				if (curAnim == params.anim)
					updateAtlasName();
		}
	}
}
