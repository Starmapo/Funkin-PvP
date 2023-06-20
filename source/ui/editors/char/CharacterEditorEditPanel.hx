package ui.editors.char;

import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import states.editors.CharacterEditorState;
import subStates.editors.char.AtlasNamePrompt;
import subStates.editors.char.BaseImageSubState;
import subStates.editors.char.HealthColorPicker;
import subStates.editors.char.NewCharacterPrompt;
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
	var animFlipXCheckbox:EditorCheckbox;
	var animFlipYCheckbox:EditorCheckbox;
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
	var loopAnimsCheckbox:EditorCheckbox;
	var loopPointStepper:EditorNumericStepper;
	var flipAllCheckbox:EditorCheckbox;
	var constantLoopingCheckbox:EditorCheckbox;
	var spacing:Int = 4;
	var inputSpacing = 125;
	var inputWidth = 250;
	var healthColorPicker:HealthColorPicker;
	var atlasNamePrompt:AtlasNamePrompt;
	var newCharacterPrompt:NewCharacterPrompt;
	var createIconSubState:BaseImageSubState;
	var createPortraitSubState:BaseImageSubState;

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
		resize(390, 320);
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
		animFlipXCheckbox = null;
		animFlipYCheckbox = null;
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
		cameraXStepper = null;
		cameraYStepper = null;
		healthIconInput = null;
		loopAnimsCheckbox = null;
		loopPointStepper = null;
		flipAllCheckbox = null;
		curAnim = null;
		healthColorPicker = FlxDestroyUtil.destroy(healthColorPicker);
		atlasNamePrompt = FlxDestroyUtil.destroy(atlasNamePrompt);
		newCharacterPrompt = FlxDestroyUtil.destroy(newCharacterPrompt);
		createIconSubState = FlxDestroyUtil.destroy(createIconSubState);
		createPortraitSubState = FlxDestroyUtil.destroy(createPortraitSubState);
	}

	function createAnimationTab()
	{
		atlasNamePrompt = new AtlasNamePrompt(state);

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
			for (anim in state.info.anims)
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

		var selectAtlasNameButton = new FlxUIButton(0, atlasNameInput.y + atlasNameInput.height + spacing, 'Select Atlas Name', function()
		{
			if (curAnim == null)
				return;

			atlasNamePrompt.anim = curAnim;
			state.openSubState(atlasNamePrompt);
		});
		selectAtlasNameButton.resize(120, selectAtlasNameButton.height);
		selectAtlasNameButton.x += (width - selectAtlasNameButton.width) / 2;
		tab.add(selectAtlasNameButton);

		var indicesLabel = new EditorText(atlasNameLabel.x, selectAtlasNameButton.y + selectAtlasNameButton.height + spacing + 1, 0, 'Indices (Optional):');
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

		var flipXLabel = new EditorText(loopLabel.x, loopLabel.y + loopLabel.height + spacing, 0, 'Flip X:');
		tab.add(flipXLabel);

		animFlipXCheckbox = new EditorCheckbox(flipXLabel.x + inputSpacing, flipXLabel.y - 1, '', 0, function()
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimFlipX(state, curAnim, animFlipXCheckbox.checked));
		});
		tab.add(animFlipXCheckbox);

		var flipYLabel = new EditorText(flipXLabel.x, flipXLabel.y + flipXLabel.height + spacing, 0, 'Flip Y:');
		tab.add(flipYLabel);

		animFlipYCheckbox = new EditorCheckbox(flipYLabel.x + inputSpacing, flipYLabel.y - 1, '', 0, function()
		{
			if (curAnim != null)
				state.actionManager.perform(new ActionChangeAnimFlipY(state, curAnim, animFlipYCheckbox.checked));
		});
		tab.add(animFlipYCheckbox);

		var offsetLabel = new EditorText(flipYLabel.x, flipYLabel.y + flipYLabel.height + spacing, 0, 'Offset:');
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
		healthColorPicker = new HealthColorPicker(state, state.info.healthColors, function(color)
		{
			state.actionManager.perform(new ActionChangeHealthColor(state, color));
		});
		newCharacterPrompt = new NewCharacterPrompt(state);

		var tab = createTab('Character');

		var imageLabel = new EditorText(4, 5, 0, 'Image:');
		tab.add(imageLabel);

		imageInput = new EditorInputText(imageLabel.x + inputSpacing, imageLabel.y - 1, inputWidth, state.info.image);
		imageInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeImage(state, text));
		});
		tab.add(imageInput);

		var danceAnimsLabel = new EditorText(imageLabel.x, imageLabel.y + imageLabel.height + spacing, 0, 'Dance Animations:');
		tab.add(danceAnimsLabel);

		danceAnimsInput = new EditorInputText(danceAnimsLabel.x + inputSpacing, danceAnimsLabel.y - 1, inputWidth, state.info.danceAnims.join(','));
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
			state.actionManager.perform(new ActionChangePositionOffset(state, [value, state.info.positionOffset[1]], state.info.positionOffset.copy()));
		});
		tab.add(positionXStepper);

		positionYStepper = new EditorNumericStepper(positionXStepper.x + positionXStepper.width + spacing, positionXStepper.y, 1, 0, null, null, 2);
		positionYStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangePositionOffset(state, [state.info.positionOffset[0], value], state.info.positionOffset.copy()));
		});
		tab.add(positionYStepper);

		var cameraLabel = new EditorText(positionLabel.x, positionLabel.y + positionLabel.height + spacing, 0, 'Camera Offset:');
		tab.add(cameraLabel);

		cameraXStepper = new EditorNumericStepper(cameraLabel.x + inputSpacing, cameraLabel.y - 1, 1, 0, null, null, 2);
		cameraXStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeCameraOffset(state, [value, state.info.cameraOffset[1]], state.info.cameraOffset.copy()));
		});
		tab.add(cameraXStepper);

		cameraYStepper = new EditorNumericStepper(cameraXStepper.x + cameraXStepper.width + spacing, cameraXStepper.y, 1, 0, null, null, 2);
		cameraYStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeCameraOffset(state, [state.info.cameraOffset[0], value], state.info.cameraOffset.copy()));
		});
		tab.add(cameraYStepper);

		var healthIconLabel = new EditorText(cameraLabel.x, cameraLabel.y + cameraLabel.height + spacing, 0, 'Health Icon:');
		tab.add(healthIconLabel);

		healthIconInput = new EditorInputText(healthIconLabel.x + inputSpacing, healthIconLabel.y - 1, inputWidth, state.info.healthIcon);
		healthIconInput.textChanged.add(function(text, lastText)
		{
			state.actionManager.perform(new ActionChangeIcon(state, text));
		});
		tab.add(healthIconInput);

		var healthColorButton = new FlxUIButton(0, healthIconLabel.y + healthIconLabel.height + spacing, 'Change Health Color', function()
		{
			state.openSubState(healthColorPicker);
		});
		healthColorButton.resize(120, healthColorButton.height);
		healthColorButton.x += (width - healthColorButton.width) / 2;
		tab.add(healthColorButton);

		var loopAnimsLabel = new EditorText(healthIconLabel.x, healthColorButton.y + healthColorButton.height + spacing, 0, 'Loop Long Note Animations:');
		tab.add(loopAnimsLabel);

		loopAnimsCheckbox = new EditorCheckbox(loopAnimsLabel.x + loopAnimsLabel.width + spacing, loopAnimsLabel.y - 1, '', 0, function()
		{
			state.actionManager.perform(new ActionChangeLoopAnims(state, loopAnimsCheckbox.checked));
		});
		tab.add(loopAnimsCheckbox);

		var loopPointLabel = new EditorText(loopAnimsLabel.x, loopAnimsLabel.y + loopAnimsLabel.height + spacing, 0, 'Long Note Loop Point:');
		tab.add(loopPointLabel);

		loopPointStepper = new EditorNumericStepper(loopPointLabel.x + inputSpacing, loopPointLabel.y - 1, 1, 0, 0, null, 0);
		loopPointStepper.valueChanged.add(function(value, lastValue)
		{
			state.actionManager.perform(new ActionChangeLoopPoint(state, Std.int(value)));
		});
		tab.add(loopPointStepper);

		var flipAllLabel = new EditorText(loopPointLabel.x, loopPointLabel.y + loopPointLabel.height + spacing, 0, 'Swap Down & Up Animations when Flipped:');
		tab.add(flipAllLabel);

		flipAllCheckbox = new EditorCheckbox(flipAllLabel.x + flipAllLabel.width + spacing, flipAllLabel.y - 1, '', 0, function()
		{
			state.actionManager.perform(new ActionChangeFlipAll(state, flipAllCheckbox.checked));
		});
		tab.add(flipAllCheckbox);

		var constantLoopingLabel = new EditorText(flipAllLabel.x, flipAllLabel.y + flipAllLabel.height + spacing, 0, 'Constant Animation Looping:');
		tab.add(constantLoopingLabel);

		constantLoopingCheckbox = new EditorCheckbox(constantLoopingLabel.x + constantLoopingLabel.width + spacing, constantLoopingLabel.y - 1, '', 0,
			function()
			{
				state.actionManager.perform(new ActionChangeConstantLooping(state, constantLoopingCheckbox.checked));
			});
		tab.add(constantLoopingCheckbox);

		var saveButton = new FlxUIButton(0, constantLoopingCheckbox.y + constantLoopingCheckbox.height + spacing, 'Save', function()
		{
			state.save();
		});

		var loadButton = new FlxUIButton(saveButton.x + saveButton.width + spacing, saveButton.y, 'Load', function()
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
			var info = CharacterInfo.loadCharacter(path.substr(cwd.length + 1));
			if (info == null)
			{
				state.notificationManager.showNotification("You must select a valid character file!", ERROR);
				return;
			}

			state.save(false);
			state.setInfo(info);
		});

		saveButton.x = (width - CoolUtil.getArrayWidth([saveButton, loadButton])) / 2;
		loadButton.x = saveButton.x + saveButton.width + spacing;
		tab.add(saveButton);
		tab.add(loadButton);

		var newCharacterButton = new FlxUIButton(0, loadButton.y + loadButton.height + spacing, 'New Character', function()
		{
			state.openSubState(newCharacterPrompt);
		});
		newCharacterButton.x += (width - newCharacterButton.width) / 2;
		tab.add(newCharacterButton);

		addGroup(tab);
	}

	function createEditorTab()
	{
		createIconSubState = new BaseImageSubState(state, 80, 80);
		createPortraitSubState = new BaseImageSubState(state, 300, 360);

		var tab = createTab('Editor');

		var gfCheckbox:EditorCheckbox = null;
		gfCheckbox = new EditorCheckbox(0, 4, 'GF as Guide Character', 0, function()
		{
			if (gfCheckbox.checked)
				state.guideChar.info = CharacterInfo.loadCharacterFromName('fnf:gf');
			else
				state.guideChar.info = CharacterInfo.loadCharacterFromName('fnf:dad');
		});
		gfCheckbox.x = (width - (gfCheckbox.width + gfCheckbox.button.label.width)) / 2;
		tab.add(gfCheckbox);

		var createIconButton = new FlxUIButton(0, gfCheckbox.y + gfCheckbox.height + spacing, 'Create Character Select Icon', function()
		{
			if (state.char.frame == null)
				return;
			state.openSubState(createIconSubState);
		});
		createIconButton.resize(160, createIconButton.height);
		createIconButton.x = (width - createIconButton.width) / 2;
		tab.add(createIconButton);

		var createPortraitButton = new FlxUIButton(0, createIconButton.y + createIconButton.height + spacing, 'Create Character Select Portrait', function()
		{
			if (state.char.frame == null)
				return;
			state.openSubState(createPortraitSubState);
		});
		createPortraitButton.resize(170, createPortraitButton.height);
		createPortraitButton.x = (width - createPortraitButton.width) / 2;
		tab.add(createPortraitButton);

		var saveFrameButton = new FlxUIButton(0, createPortraitButton.y + createPortraitButton.height + spacing, 'Save Current Frame', function()
		{
			state.saveFrame(state.info.name + '.png');
		});
		saveFrameButton.resize(120, saveFrameButton.height);
		saveFrameButton.x = (width - saveFrameButton.width) / 2;
		tab.add(saveFrameButton);

		addGroup(tab);
	}

	public function updateCurAnim()
	{
		curAnim = state.info.getAnim(state.curAnim);
		updateName();
		updateAtlasName();
		updateIndices();
		updateFPS();
		updateLoop();
		updateAnimFlipX();
		updateAnimFlipY();
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

	function updateAnimFlipX()
	{
		animFlipXCheckbox.checked = curAnim != null ? curAnim.flipX : false;
	}

	function updateAnimFlipY()
	{
		animFlipYCheckbox.checked = curAnim != null ? curAnim.flipY : false;
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
		updateHealthColor();
		updateLoopAnims();
		updateLoopPoint();
		updateFlipAll();
		updateConstantLooping();

		updateCurAnim();

		atlasNamePrompt.refreshAtlasNames();
		newCharacterPrompt.updateMod();
		createIconSubState.path = 'images/characterSelect/icons/${state.info.name}.png';
		createPortraitSubState.path = 'images/characterSelect/portraits/${state.info.name}.png';
	}

	function updateImage()
	{
		imageInput.text = state.info.image;
	}

	function updateDanceAnims()
	{
		danceAnimsInput.text = state.info.danceAnims.join(',');
	}

	function updateFlipX()
	{
		flipXCheckbox.checked = state.info.flipX;
	}

	function updateScale()
	{
		scaleStepper.value = state.info.scale;
	}

	function updateAntialiasing()
	{
		antialiasingCheckbox.checked = state.info.antialiasing;
	}

	public function updatePositionOffset()
	{
		positionXStepper.value = state.info.positionOffset[0];
		positionYStepper.value = state.info.positionOffset[1];
	}

	public function updateCameraOffset()
	{
		cameraXStepper.value = state.info.cameraOffset[0];
		cameraYStepper.value = state.info.cameraOffset[1];
	}

	function updateHealthIcon()
	{
		healthIconInput.text = state.info.healthIcon;
	}

	function updateHealthColor()
	{
		healthColorPicker.color = state.info.healthColors;
	}

	function updateLoopAnims()
	{
		loopAnimsCheckbox.checked = state.info.loopAnimsOnHold;
	}

	function updateLoopPoint()
	{
		loopPointStepper.value = state.info.holdLoopPoint;
	}

	function updateFlipAll()
	{
		flipAllCheckbox.checked = state.info.flipAll;
	}

	function updateConstantLooping()
	{
		constantLoopingCheckbox.checked = state.info.constantLooping;
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
			case CharacterEditorActionManager.CHANGE_HEALTH_COLOR:
				updateHealthColor();
			case CharacterEditorActionManager.CHANGE_LOOP_ANIMS:
				updateLoopAnims();
			case CharacterEditorActionManager.CHANGE_LOOP_POINT:
				updateLoopPoint();
			case CharacterEditorActionManager.CHANGE_FLIP_ALL:
				updateFlipAll();
			case CharacterEditorActionManager.CHANGE_CONSTANT_LOOPING:
				updateConstantLooping();
			case CharacterEditorActionManager.REMOVE_ANIM:
				updateCurAnim();
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
			case CharacterEditorActionManager.CHANGE_ANIM_FLIP_X:
				if (curAnim == params.anim)
					updateAnimFlipX();
			case CharacterEditorActionManager.CHANGE_ANIM_FLIP_Y:
				if (curAnim == params.anim)
					updateAnimFlipY();
			case CharacterEditorActionManager.CHANGE_ANIM_NEXT:
				if (curAnim == params.anim)
					updateNextAnim();
		}
	}
}
