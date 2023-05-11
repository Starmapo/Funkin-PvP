package states.editors;

import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.io.Path;
import openfl.display.PNGEncoderOptions;
import openfl.events.Event;
import openfl.net.FileReference;
import sprites.game.Character;
import sys.io.File;
import systools.Dialogs;
import ui.editors.NotificationManager;

using StringTools;

class CharacterEditorState extends FNFState
{
	var charInfo:CharacterInfo;
	var char:Character;
	var camPos:FlxObject;
	var animText:FlxText;
	var timeSinceLastChange:Float = 0;
	var ghostChar:Character;
	var ghostAnim:String;
	var infoText:FlxText;
	var dragMousePos:FlxPoint;
	var dragPositionOffset:Array<Float>;
	var guideChar:Character;
	var notificationManager:NotificationManager;
	var buttonGroup:FlxTypedGroup<FlxUIButton>;
	var camIndicator:FlxSprite;
	var draggingCam:Bool = false;

	public function new(?charInfo:CharacterInfo)
	{
		super();
		if (charInfo == null)
			charInfo = CharacterInfo.loadCharacterFromName('fnf:dad');
		this.charInfo = charInfo;

		persistentUpdate = true;
	}

	override function create()
	{
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		bg.scrollFactor.set();
		add(bg);

		guideChar = new Character(0, 0, CharacterInfo.loadCharacterFromName('fnf:dad'));
		guideChar.color = 0xFF886666;
		guideChar.alpha = 0.6;
		guideChar.animation.finish();
		add(guideChar);

		ghostChar = new Character(0, 0, charInfo);
		ghostChar.visible = false;
		ghostChar.color = 0xFF666688;
		ghostChar.alpha = 0.6;
		add(ghostChar);

		char = new Character(0, 0, charInfo);
		char.alpha = 0.85;
		char.debugMode = true;
		add(char);

		camIndicator = new FlxSprite().loadGraphic(Paths.getImage('editors/cross'));
		camIndicator.scale.set(2, 2);
		camIndicator.updateHitbox();
		updateCamIndicator();
		add(camIndicator);

		animText = new FlxText(5, 0, FlxG.width - 10);
		animText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);

		infoText = new FlxText(5, 0, FlxG.width - 10);
		infoText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		infoText.scrollFactor.set();
		add(infoText);

		buttonGroup = new FlxTypedGroup();
		add(buttonGroup);

		var loadButton = new FlxUIButton(FlxG.width, 0, 'Load', function()
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
				notificationManager.showNotification("You must select a character inside of the game's directory!", ERROR);
				return;
			}
			var charInfo = CharacterInfo.loadCharacter(path.substr(cwd.length + 1));
			if (charInfo == null)
			{
				notificationManager.showNotification("You must select a valid character file!", ERROR);
				return;
			}

			FlxG.switchState(new CharacterEditorState(charInfo));
		});
		loadButton.x -= loadButton.width;
		buttonGroup.add(loadButton);

		var saveButton = new FlxUIButton(FlxG.width, loadButton.y + loadButton.height + 4, 'Save', function()
		{
			save();
			notificationManager.showNotification('Character successfully saved!', SUCCESS);
		});
		saveButton.x -= saveButton.width;
		buttonGroup.add(saveButton);

		var saveFrameButton = new FlxUIButton(FlxG.width, saveButton.y + saveButton.height + 4, 'Save Current Frame', function()
		{
			saveFrame();
		});
		saveFrameButton.resize(160, saveFrameButton.height);
		saveFrameButton.autoCenterLabel();
		saveFrameButton.x -= saveFrameButton.width;
		buttonGroup.add(saveFrameButton);

		notificationManager = new NotificationManager();
		add(notificationManager);

		camPos = new FlxObject();
		add(camPos);
		FlxG.camera.follow(camPos);

		resetCamPos();
		FlxG.camera.snapToTarget();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.anyPressed([I, J, K, L]))
		{
			var angle = FlxG.keys.angleFromKeys([I, J, K, L]);
			camPos.velocity.setPolarDegrees(900, angle);
		}
		else
			camPos.velocity.set();

		if (FlxG.keys.justPressed.R)
			resetCamPos();

		if (FlxG.keys.justPressed.W)
			changeAnimIndex(-1);
		if (FlxG.keys.justPressed.S)
			changeAnimIndex(1);

		timeSinceLastChange += elapsed;
		if (char.animation.curAnim != null)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.keys.pressed.SHIFT)
					char.animation.curAnim.restart();
				else
				{
					char.animation.curAnim.paused = !char.animation.curAnim.paused;
					if (char.animation.curAnim.finished)
						char.animation.curAnim.restart();
				}
			}
			if (char.animation.curAnim.paused)
			{
				if (FlxG.keys.justPressed.COMMA)
					changeFrameIndex(-1);
				if (FlxG.keys.justPressed.PERIOD)
					changeFrameIndex(1);
			}
			if (FlxG.keys.justPressed.HOME)
				char.animation.curAnim.curFrame = 0;
			if (FlxG.keys.justPressed.END && char.animation.curAnim.numFrames > 0)
				char.animation.curAnim.curFrame = char.animation.curAnim.numFrames - 1;

			var canHold = timeSinceLastChange >= 0.1;
			var mult = FlxG.keys.pressed.SHIFT ? 10 : 1;
			if (FlxG.keys.justPressed.LEFT || (FlxG.keys.pressed.LEFT && canHold))
				changeOffsetOrPos(-1 * mult);
			if (FlxG.keys.justPressed.RIGHT || (FlxG.keys.pressed.RIGHT && canHold))
				changeOffsetOrPos(1 * mult);
			if (FlxG.keys.justPressed.UP || (FlxG.keys.pressed.UP && canHold))
				changeOffsetOrPos(0, -1 * mult);
			if (FlxG.keys.justPressed.DOWN || (FlxG.keys.pressed.DOWN && canHold))
				changeOffsetOrPos(0, 1 * mult);

			if (FlxG.keys.justPressed.G)
				setGhostAnim(char.animation.name);

			if (FlxG.keys.justPressed.H)
				guideChar.visible = !guideChar.visible;
		}

		if (dragMousePos != null)
		{
			var delta = FlxG.mouse.getWorldPosition() - dragMousePos;
			var offset = draggingCam ? charInfo.cameraOffset : charInfo.positionOffset;
			offset[0] = dragPositionOffset[0] + FlxMath.roundDecimal(delta.x, 2);
			offset[1] = dragPositionOffset[1] + FlxMath.roundDecimal(delta.y, 2);

			if (draggingCam)
				updateCamIndicator();
			else
			{
				char.updatePosition();
				ghostChar.updatePosition();
			}

			if (FlxG.mouse.released)
			{
				dragMousePos = null;
				dragPositionOffset = null;
			}
		}

		if (FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			if (FlxG.mouse.overlaps(camIndicator))
			{
				dragMousePos = mousePos;
				dragPositionOffset = charInfo.cameraOffset.copy();
				draggingCam = true;
			}
			else if (FlxG.mouse.overlaps(char))
			{
				dragMousePos = mousePos;
				dragPositionOffset = charInfo.positionOffset.copy();
				draggingCam = false;
			}
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			persistentUpdate = false;
			FlxG.switchState(new ToolboxState());
		}

		camPos.update(elapsed);
		ghostChar.update(elapsed);
		char.update(elapsed);
		updateAnimText();
		updateInfoText();
		buttonGroup.update(elapsed);
		notificationManager.update(elapsed);

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}

	function resetCamPos()
	{
		camPos.setPosition(camIndicator.x + (camIndicator.width / 2), camIndicator.y + (camIndicator.height / 2));
	}

	function updateAnimText()
	{
		var curFrame = 0;
		var numFrames = 0;
		if (char.animation.curAnim != null)
		{
			curFrame = char.animation.curAnim.curFrame + 1;
			numFrames = char.animation.curAnim.numFrames;
		}

		var newText = 'Animation: '
			+ char.animation.name
			+ '\nFrame: '
			+ curFrame
			+ ' / '
			+ numFrames
			+ '\nOffset: '
			+ char.getCurAnimOffset();
		if (animText.text != newText)
			animText.text = newText;
	}

	function updateInfoText()
	{
		var newText = 'Position Offset: ' + charInfo.positionOffset + '\nCamera Offset: ' + charInfo.cameraOffset;
		if (infoText.text != newText)
		{
			infoText.text = newText;
			infoText.y = FlxG.height - infoText.height;
		}
	}

	function changeAnimIndex(change:Int)
	{
		var index = char.getCurAnimIndex();
		index = FlxMath.wrapInt(index + change, 0, charInfo.anims.length - 1);

		var anim = charInfo.anims[index];
		if (anim != null)
		{
			var paused = char.animation.paused;

			char.playAnim(anim.name, true);

			if (paused)
				char.animation.pause();
		}
	}

	function changeFrameIndex(change:Int)
	{
		char.animation.curAnim.curFrame = FlxMath.wrapInt(char.animation.curAnim.curFrame + change, 0, char.animation.curAnim.numFrames - 1);
	}

	function changeOffset(xChange:Int, yChange:Int = 0)
	{
		var curAnim = char.getCurAnim();
		curAnim.offset[0] -= xChange;
		curAnim.offset[1] -= yChange;

		var offset = char.offsets.get(curAnim.name);
		offset[0] -= xChange;
		offset[1] -= yChange;

		char.updateOffset();
		if (ghostChar.animation.name == char.animation.name)
			ghostChar.updateOffset();

		timeSinceLastChange = 0;
	}

	function changePositionOffset(xChange:Int, yChange:Int = 0)
	{
		charInfo.positionOffset[0] += xChange;
		charInfo.positionOffset[1] += yChange;

		char.updatePosition();
		if (ghostChar.animation.name == char.animation.name)
			ghostChar.updatePosition();

		timeSinceLastChange = 0;
	}

	function changeOffsetOrPos(xChange:Int, yChange:Int = 0)
	{
		if (FlxG.keys.pressed.ALT)
			changePositionOffset(xChange, yChange);
		else
			changeOffset(xChange, yChange);
	}

	function setGhostAnim(name:String)
	{
		if (ghostAnim != name)
		{
			ghostAnim = name;
			ghostChar.visible = true;
			ghostChar.playAnim(name, true);
		}
		else
		{
			ghostAnim = null;
			ghostChar.visible = false;
		}
	}

	function save()
	{
		charInfo.save(Path.join([charInfo.directory, charInfo.charName + '.json']));
	}

	function updateCamIndicator()
	{
		camIndicator.setPosition(char.x + (char.startWidth / 2) + charInfo.cameraOffset[0], char.y + (char.startHeight / 2) + charInfo.cameraOffset[1]);
	}

	function saveFrame()
	{
		var frame = char.frame;
		if (frame == null)
			return;

		var bytes = char.pixels.encode(frame.frame.copyToFlash(), new PNGEncoderOptions());
		File.saveBytes(charInfo.charName + '.png', bytes);
		notificationManager.showNotification('Image successfully saved!', SUCCESS);
	}
}
