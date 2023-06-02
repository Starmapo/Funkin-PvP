package ui.editors.char;

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
	var danceAnimsInput:EditorInputText;
	var flipXCheckbox:EditorCheckbox;
	var scaleStepper:EditorNumericStepper;
	var antialiasingCheckbox:EditorCheckbox;
	var positionXStepper:EditorNumericStepper;
	var positionYStepper:EditorNumericStepper;
	var cameraXStepper:EditorNumericStepper;
	var cameraYStepper:EditorNumericStepper;
	var healthIconInput:EditorInputText;
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
		danceAnimsInput = null;
		flipXCheckbox = null;
		scaleStepper = null;
		antialiasingCheckbox = null;
		positionXStepper = null;
		positionYStepper = null;
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

		var danceAnimsLabel = new EditorText(imageLabel.x, imageLabel.y + imageLabel.height + spacing, 0, 'Dance Animations:');
		tab.add(danceAnimsLabel);

		danceAnimsInput = new EditorInputText(danceAnimsLabel.x + inputSpacing, danceAnimsLabel.y - 1, inputWidth, state.charInfo.danceAnims.join(','));
		danceAnimsInput.textChanged.add(function(text, lastText)
		{
			var anims = text.split(',');
			if (anims.length < 1 || anims[0].length < 1)
			{
				danceAnimsInput.text = lastText;
				state.notificationManager.showNotification('You must have atleast 1 dance animation!', ERROR);
				return;
			}

			state.actionManager.perform(new ActionChangeDanceAnims(state, anims));
		});
		tab.add(danceAnimsInput);

		var flipXLabel = new EditorText(danceAnimsLabel.x, danceAnimsLabel.y + danceAnimsLabel.height + spacing, 0, 'Flipped Horizontally:');
		tab.add(flipXLabel);

		flipXCheckbox = new EditorCheckbox(flipXLabel.x + inputSpacing, flipXLabel.y - 1, '', 0, function()
		{
			state.actionManager.perform(new ActionChangeFlipX(state, flipXCheckbox.checked));
		});
		tab.add(flipXCheckbox);

		var scaleLabel = new EditorText(flipXLabel.x, flipXLabel.y + flipXLabel.height + spacing, 0, 'Scale:');
		tab.add(scaleLabel);

		scaleStepper = new EditorNumericStepper(scaleLabel.x + inputSpacing, scaleLabel.y - 1, 0.1, 1, 0.01, 100, 2);
		scaleStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeScale(state, value));
		});
		tab.add(scaleStepper);

		var antialiasingLabel = new EditorText(scaleLabel.x, scaleLabel.y + scaleLabel.height + spacing, 0, 'Antialiasing:');
		tab.add(antialiasingLabel);

		antialiasingCheckbox = new EditorCheckbox(antialiasingLabel.x + inputSpacing, antialiasingLabel.y - 1, '', 0, function()
		{
			state.actionManager.perform(new ActionChangeAntialiasing(state, antialiasingCheckbox.checked));
		});
		tab.add(antialiasingCheckbox);

		var positionLabel = new EditorText(antialiasingLabel.x, antialiasingLabel.y + antialiasingLabel.height + spacing, 0, 'Position Offset:');
		tab.add(positionLabel);

		positionXStepper = new EditorNumericStepper(positionLabel.x + inputSpacing, positionLabel.y - 1, 1, 0, null, null, 2);
		positionXStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangePositionOffset(state, [value, state.charInfo.positionOffset[1]],
				state.charInfo.positionOffset.copy()));
		});
		tab.add(positionXStepper);

		positionYStepper = new EditorNumericStepper(positionXStepper.x + positionXStepper.width + spacing, positionXStepper.y, 1, 0, null, null, 2);
		positionYStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangePositionOffset(state, [state.charInfo.positionOffset[0], value],
				state.charInfo.positionOffset.copy()));
		});
		tab.add(positionYStepper);

		var cameraLabel = new EditorText(positionLabel.x, positionLabel.y + positionLabel.height + spacing, 0, 'Camera Offset:');
		tab.add(cameraLabel);

		cameraXStepper = new EditorNumericStepper(cameraLabel.x + inputSpacing, cameraLabel.y - 1, 1, 0, null, null, 2);
		cameraXStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeCameraOffset(state, [value, state.charInfo.cameraOffset[1]], state.charInfo.cameraOffset.copy()));
		});
		tab.add(cameraXStepper);

		cameraYStepper = new EditorNumericStepper(cameraXStepper.x + cameraXStepper.width + spacing, cameraXStepper.y, 1, 0, null, null, 2);
		cameraYStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeCameraOffset(state, [state.charInfo.cameraOffset[0], value], state.charInfo.cameraOffset.copy()));
		});
		tab.add(cameraYStepper);

		var healthIconLabel = new EditorText(cameraLabel.x, cameraLabel.y + cameraLabel.height + spacing, 0, 'Health Icon:');
		tab.add(healthIconLabel);

		healthIconInput = new EditorInputText(healthIconLabel.x + inputSpacing, healthIconLabel.y - 1, inputWidth, state.charInfo.healthIcon);
		healthIconInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeIcon(state, text));
		});
		tab.add(healthIconInput);

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
		updateDanceAnims();
		updateFlipX();
		updateScale();
		updateAntialiasing();
		updatePositionOffset();
		updateCameraOffset();
		updateHealthIcon();

		updateCurAnim();
	}

	function updateImage()
	{
		imageInput.text = state.charInfo.image;
	}

	function updateDanceAnims()
	{
		danceAnimsInput.text = state.charInfo.danceAnims.join(',');
	}

	function updateFlipX()
	{
		flipXCheckbox.checked = state.charInfo.flipX;
	}

	function updateScale()
	{
		scaleStepper.value = state.charInfo.scale;
	}

	function updateAntialiasing()
	{
		antialiasingCheckbox.checked = state.charInfo.antialiasing;
	}

	public function updatePositionOffset()
	{
		positionXStepper.value = state.charInfo.positionOffset[0];
		positionYStepper.value = state.charInfo.positionOffset[1];
	}

	public function updateCameraOffset()
	{
		cameraXStepper.value = state.charInfo.cameraOffset[0];
		cameraYStepper.value = state.charInfo.cameraOffset[1];
	}

	function updateHealthIcon()
	{
		healthIconInput.text = state.charInfo.healthIcon;
	}

	function onEvent(event:String, params:Dynamic)
	{
		switch (event)
		{
			case CharacterEditorActionManager.CHANGE_IMAGE:
				updateImage();
			case CharacterEditorActionManager.CHANGE_DANCE_ANIMS:
				updateDanceAnims();
			case CharacterEditorActionManager.CHANGE_FLIP_X:
				updateFlipX();
			case CharacterEditorActionManager.CHANGE_SCALE:
				updateScale();
			case CharacterEditorActionManager.CHANGE_ANTIALIASING:
				updateAntialiasing();
			case CharacterEditorActionManager.CHANGE_POSITION_OFFSET:
				updatePositionOffset();
			case CharacterEditorActionManager.CHANGE_CAMERA_OFFSET:
				updateCameraOffset();
			case CharacterEditorActionManager.CHANGE_ICON:
				updateHealthIcon();
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
