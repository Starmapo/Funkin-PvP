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
	var indicesInput:EditorInputText;
	var fpsStepper:EditorNumericStepper;
	var loopCheckbox:EditorCheckbox;
	var offsetXStepper:EditorNumericStepper;
	var offsetYStepper:EditorNumericStepper;
	var nextAnimInput:EditorInputText;
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

		selected_tab_id = 'Character';

		state.actionManager.onEvent.add(onEvent);
	}

	override function destroy()
	{
		super.destroy();
		state = null;
		nameInput = null;
		atlasNameInput = null;
		indicesInput = null;
		fpsStepper = null;
		loopCheckbox = null;
		offsetXStepper = null;
		offsetYStepper = null;
		nextAnimInput = null;
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

		var indicesLabel = new EditorText(atlasNameLabel.x, atlasNameLabel.y + atlasNameLabel.height + spacing, 0, 'Indices (Optional):');
		tab.add(indicesLabel);

		indicesInput = new EditorInputText(indicesLabel.x + inputSpacing, indicesLabel.y - 1, inputWidth);
		indicesInput.textChanged.add(function(text, lastText)
		{
			var indices:Array<Int> = [];
			for (t in text.split(','))
			{
				if (t.length > 0)
				{
					var int = Std.parseInt(t);
					if (int != null)
						indices.push(int);
				}
			}
			state.actionManager.perform(new ActionChangeAnimIndices(state, curAnim, indices));
		});
		tab.add(indicesInput);

		var fpsLabel = new EditorText(indicesLabel.x, indicesLabel.y + indicesLabel.height + spacing, 0, 'Frame rate:');
		tab.add(fpsLabel);

		fpsStepper = new EditorNumericStepper(fpsLabel.x + inputSpacing, fpsLabel.y - 1, 1, 24, 0, 1000, 2);
		fpsStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeAnimFPS(state, curAnim, value));
		});
		tab.add(fpsStepper);

		var loopLabel = new EditorText(fpsLabel.x, fpsLabel.y + fpsLabel.height + spacing, 0, 'Looped:');
		tab.add(loopLabel);

		loopCheckbox = new EditorCheckbox(loopLabel.x + inputSpacing, loopLabel.y - 1, '', 0, function()
		{
			state.actionManager.perform(new ActionChangeAnimLoop(state, curAnim, loopCheckbox.checked));
		});
		tab.add(loopCheckbox);

		var offsetLabel = new EditorText(loopLabel.x, loopLabel.y + loopLabel.height + spacing, 0, 'Offset:');
		tab.add(offsetLabel);

		offsetXStepper = new EditorNumericStepper(offsetLabel.x + inputSpacing, offsetLabel.y - 1, 1, 0, null, null, 2);
		offsetXStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeAnimOffset(state, curAnim, [value, curAnim.offset[1]], curAnim.offset.copy()));
		});
		tab.add(offsetXStepper);

		offsetYStepper = new EditorNumericStepper(offsetXStepper.x + offsetXStepper.width + spacing, offsetXStepper.y, 1, 0, null, null, 2);
		offsetYStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeAnimOffset(state, curAnim, [curAnim.offset[0], value], curAnim.offset.copy()));
		});
		tab.add(offsetYStepper);

		var nextAnimLabel = new EditorText(offsetLabel.x, offsetLabel.y + offsetLabel.height + spacing, 0, 'Next Animation:');
		tab.add(nextAnimLabel);

		nextAnimInput = new EditorInputText(nextAnimLabel.x + inputSpacing, nextAnimLabel.y - 1, inputWidth);
		nextAnimInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeAnimNext(state, curAnim, text));
		});
		tab.add(nextAnimInput);

		addGroup(tab);
	}

	function createCharacterTab()
	{
		var tab = createTab('Character');

		addGroup(tab);
	}

	public function updateCurAnim()
	{
		curAnim = state.char.getCurAnim();
		updateName();
		updateAtlasName();
		updateIndices();
		updateFPS();
		updateLoop();
		updateOffset();
		updateNextAnim();
	}

	function updateName()
	{
		nameInput.text = curAnim != null ? curAnim.name : '';
	}

	function updateAtlasName()
	{
		atlasNameInput.text = curAnim != null ? curAnim.atlasName : '';
	}

	function updateIndices()
	{
		indicesInput.text = curAnim != null ? curAnim.indices.join(',') : '';
	}

	function updateFPS()
	{
		fpsStepper.value = curAnim != null ? curAnim.fps : 0;
	}

	function updateLoop()
	{
		loopCheckbox.checked = curAnim != null ? curAnim.loop : false;
	}

	public function updateOffset()
	{
		offsetXStepper.value = curAnim != null ? curAnim.offset[0] : 0;
		offsetYStepper.value = curAnim != null ? curAnim.offset[1] : 0;
	}

	function updateNextAnim()
	{
		nextAnimInput.text = curAnim != null ? curAnim.nextAnim : '';
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
			case CharacterEditorActionManager.CHANGE_ANIM_INDICES:
				if (curAnim == params.anim)
					updateIndices();
			case CharacterEditorActionManager.CHANGE_ANIM_FPS:
				if (curAnim == params.anim)
					updateFPS();
			case CharacterEditorActionManager.CHANGE_ANIM_LOOP:
				if (curAnim == params.anim)
					updateLoop();
			case CharacterEditorActionManager.CHANGE_ANIM_NEXT:
				if (curAnim == params.anim)
					updateNextAnim();
		}
	}
}
