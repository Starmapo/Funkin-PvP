package ui.editors.char;

import data.char.CharacterInfo.AnimInfo;
import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import haxe.io.Path;
import states.editors.CharacterEditorState;
import systools.Dialogs;
import util.editors.char.CharacterEditorActionManager;

using StringTools;

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
	var imageInput:EditorInputText;
	var spacing:Int = 4;
	var inputSpacing = 125;
	var inputWidth = 250;

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
			},
			{
				name: 'Editor',
				label: 'Editor'
			}
		]);
		resize(390, 250);
		x = FlxG.width - width - 10;
		screenCenter(Y);
		this.state = state;

		createAnimationTab();
		createCharacterTab();
		createEditorTab();

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
		imageInput = null;
		curAnim = null;
	}

	function createAnimationTab()
	{
		var tab = createTab('Animation');

		var nameLabel = new EditorText(4, 5, 0, 'Name:');
		tab.add(nameLabel);

		nameInput = new EditorInputText(nameLabel.x + inputSpacing, 4, inputWidth);
		nameInput.textChanged.add(function(text, lastText)
		{
			if (curAnim == null)
				return;
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
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimAtlasName(state, curAnim, text));
		});
		tab.add(atlasNameInput);

		var indicesLabel = new EditorText(atlasNameLabel.x, atlasNameLabel.y + atlasNameLabel.height + spacing, 0, 'Indices (Optional):');
		tab.add(indicesLabel);

		indicesInput = new EditorInputText(indicesLabel.x + inputSpacing, indicesLabel.y - 1, inputWidth);
		indicesInput.textChanged.add(function(text, lastText)
		{
			if (curAnim == null)
				return;

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
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimFPS(state, curAnim, value));
		});
		tab.add(fpsStepper);

		var loopLabel = new EditorText(fpsLabel.x, fpsLabel.y + fpsLabel.height + spacing, 0, 'Looped:');
		tab.add(loopLabel);

		loopCheckbox = new EditorCheckbox(loopLabel.x + inputSpacing, loopLabel.y - 1, '', 0, function()
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimLoop(state, curAnim, loopCheckbox.checked));
		});
		tab.add(loopCheckbox);

		var offsetLabel = new EditorText(loopLabel.x, loopLabel.y + loopLabel.height + spacing, 0, 'Offset:');
		tab.add(offsetLabel);

		offsetXStepper = new EditorNumericStepper(offsetLabel.x + inputSpacing, offsetLabel.y - 1, 1, 0, null, null, 2);
		offsetXStepper.valueChanged.add(function(value, lastValue)
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimOffset(state, curAnim, [value, curAnim.offset[1]], curAnim.offset.copy()));
		});
		tab.add(offsetXStepper);

		offsetYStepper = new EditorNumericStepper(offsetXStepper.x + offsetXStepper.width + spacing, offsetXStepper.y, 1, 0, null, null, 2);
		offsetYStepper.valueChanged.add(function(value, lastValue)
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimOffset(state, curAnim, [curAnim.offset[0], value], curAnim.offset.copy()));
		});
		tab.add(offsetYStepper);

		var nextAnimLabel = new EditorText(offsetLabel.x, offsetLabel.y + offsetLabel.height + spacing, 0, 'Next Animation:');
		tab.add(nextAnimLabel);

		nextAnimInput = new EditorInputText(nextAnimLabel.x + inputSpacing, nextAnimLabel.y - 1, inputWidth);
		nextAnimInput.textChanged.add(function(text, lastText)
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimNext(state, curAnim, text));
		});
		tab.add(nextAnimInput);

		addGroup(tab);
	}

	function createCharacterTab()
	{
		var tab = createTab('Character');

		var imageLabel = new EditorText(4, 5, 0, 'Image:');
		tab.add(imageLabel);

		imageInput = new EditorInputText(imageLabel.x + inputSpacing, imageLabel.y - 1, inputWidth, state.charInfo.image);
		imageInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeImage(state, text));
		});
		tab.add(imageInput);

		addGroup(tab);
	}

	function createEditorTab()
	{
		var tab = createTab('Editor');

		var loadButton = new FlxUIButton(0, 4, 'Load', function()
		{
			var result = Dialogs.openFile("Select character inside the game's directory to load", '', {
				count: 1,
				descriptions: ['JSON files'],
				extensions: ['*.json']
			});
			if (result == null || result[0] == null)
				return;

			var path = Path.normalize(result[0]);
			var cwd = Path.normalize(Sys.getCwd());
			if (!path.startsWith(cwd))
			{
				state.notificationManager.showNotification("You must select a character inside of the game's directory!", ERROR);
				return;
			}
			var charInfo = CharacterInfo.loadCharacter(path.substr(cwd.length + 1));
			if (charInfo == null)
			{
				state.notificationManager.showNotification("You must select a valid character file!", ERROR);
				return;
			}

			state.actionManager.reset();
			state.charInfo = charInfo;
			state.reloadCharInfo();
		});
		loadButton.x = (width - loadButton.width) / 2;
		tab.add(loadButton);

		var saveButton = new FlxUIButton(0, loadButton.y + loadButton.height + 4, 'Save', function()
		{
			state.save();
		});
		saveButton.x = (width - saveButton.width) / 2;
		tab.add(saveButton);

		var saveFrameButton = new FlxUIButton(FlxG.width, saveButton.y + saveButton.height + 4, 'Save Current Frame', function()
		{
			state.saveFrame(state.charInfo.name + '.png');
		});
		saveFrameButton.resize(160, saveFrameButton.height);
		saveFrameButton.autoCenterLabel();
		saveFrameButton.x = (width - saveFrameButton.width) / 2;
		tab.add(saveFrameButton);

		var gfCheckbox:EditorCheckbox = null;
		gfCheckbox = new EditorCheckbox(FlxG.width, saveFrameButton.y + saveFrameButton.height + 4, 'GF as Guide Character', 0, function()
		{
			if (gfCheckbox.checked)
				state.guideChar.charInfo = CharacterInfo.loadCharacterFromName('fnf:gf');
			else
				state.guideChar.charInfo = CharacterInfo.loadCharacterFromName('fnf:dad');

			state.guideChar.animation.finish();
		});
		gfCheckbox.x = (width - (gfCheckbox.width + gfCheckbox.button.label.width)) / 2;
		tab.add(gfCheckbox);

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

	public function updateChar()
	{
		updateImage();

		updateCurAnim();
	}

	function updateImage()
	{
		imageInput.text = state.charInfo.image;
	}

	function onEvent(event:String, params:Dynamic)
	{
		switch (event)
		{
			case CharacterEditorActionManager.CHANGE_IMAGE:
				updateImage();
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
