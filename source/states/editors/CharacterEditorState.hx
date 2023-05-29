package states.editors;

import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import lime.system.System;
import openfl.display.PNGEncoderOptions;
import sprites.game.BGSprite;
import sprites.game.Character;
import sys.io.File;
import systools.Dialogs;
import ui.editors.EditorCheckbox;
import ui.editors.NotificationManager;
import ui.editors.char.CharacterEditorToolPanel;
import util.DiscordClient;
import util.bindable.Bindable;

using StringTools;

class CharacterEditorState extends FNFState
{
	static var CHAR_X:Int = 100;
	static var CHAR_Y:Int = 100;

	public var currentTool:Bindable<MoveTool> = new Bindable(ANIM);

	var charInfo:CharacterInfo;
	var char:Character;
	var camPos:FlxObject;
	var animText:FlxText;
	var timeSinceLastChange:Float = 0;
	var ghostChar:Character;
	var ghostAnim:String;
	var dragMousePos:FlxPoint;
	var dragPositionOffset:Array<Float>;
	var guideChar:Character;
	var notificationManager:NotificationManager;
	var uiGroup:FlxGroup;
	var camIndicator:FlxSprite;
	var dragging:Int = 0;
	var toolPanel:CharacterEditorToolPanel;

	public function new(?charInfo:CharacterInfo)
	{
		super();
		if (charInfo == null)
			charInfo = CharacterInfo.loadCharacterFromName('fnf:bf');
		this.charInfo = charInfo;

		persistentUpdate = true;
	}

	override function destroy()
	{
		super.destroy();
		charInfo = FlxDestroyUtil.destroy(charInfo);
		char = null;
		camPos = null;
		animText = null;
		ghostChar = null;
		dragMousePos = FlxDestroyUtil.put(dragMousePos);
		guideChar = null;
		notificationManager = null;
		uiGroup = null;
		camIndicator = null;
	}

	override function create()
	{
		DiscordClient.changePresence(null, "Character Editor");

		var bg = new BGSprite('fnf:stages/stage/stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront = new BGSprite('fnf:stages/stage/stagefront', -650, 600, 0.9, 0.9);
		stageFront.scale.set(1.1, 1.1);
		stageFront.updateHitbox();
		add(stageFront);

		guideChar = new Character(CHAR_X, CHAR_Y, CharacterInfo.loadCharacterFromName('fnf:dad'));
		guideChar.color = 0xFF886666;
		guideChar.alpha = 0.6;
		guideChar.animation.finish();
		add(guideChar);

		ghostChar = new Character(CHAR_X, CHAR_Y, charInfo);
		ghostChar.visible = false;
		ghostChar.color = 0xFF666688;
		ghostChar.alpha = 0.6;
		add(ghostChar);

		char = new Character(CHAR_X, CHAR_Y, charInfo);
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

		toolPanel = new CharacterEditorToolPanel(this);
		add(toolPanel);

		uiGroup = new FlxTypedGroup();
		add(uiGroup);

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

			this.charInfo = charInfo;
			ghostChar.charInfo = charInfo;
			char.charInfo = charInfo;

			updateCamIndicator();
			updateAnimText();

			resetCamPos();
			FlxG.camera.snapToTarget();
		});
		loadButton.x -= loadButton.width;
		uiGroup.add(loadButton);

		var saveButton = new FlxUIButton(FlxG.width, loadButton.y + loadButton.height + 4, 'Save', function()
		{
			save();
			notificationManager.showNotification('Character successfully saved!', SUCCESS);
		});
		saveButton.x -= saveButton.width;
		uiGroup.add(saveButton);

		var saveFrameButton = new FlxUIButton(FlxG.width, saveButton.y + saveButton.height + 4, 'Save Current Frame', function()
		{
			saveFrame(charInfo.name + '.png');
		});
		saveFrameButton.resize(160, saveFrameButton.height);
		saveFrameButton.autoCenterLabel();
		saveFrameButton.x -= saveFrameButton.width;
		uiGroup.add(saveFrameButton);

		var gfCheckbox:EditorCheckbox = null;
		gfCheckbox = new EditorCheckbox(FlxG.width, saveFrameButton.y + saveFrameButton.height + 4, 'GF as Guide Character', 100, function()
		{
			if (gfCheckbox.checked)
				guideChar.charInfo = CharacterInfo.loadCharacterFromName('fnf:gf');
			else
				guideChar.charInfo = CharacterInfo.loadCharacterFromName('fnf:dad');

			guideChar.animation.finish();
		});
		gfCheckbox.x -= 80;
		gfCheckbox.scrollFactor.set();
		uiGroup.add(gfCheckbox);

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
				changeAnimOrPos(-1 * mult);
			if (FlxG.keys.justPressed.RIGHT || (FlxG.keys.pressed.RIGHT && canHold))
				changeAnimOrPos(1 * mult);
			if (FlxG.keys.justPressed.UP || (FlxG.keys.pressed.UP && canHold))
				changeAnimOrPos(0, -1 * mult);
			if (FlxG.keys.justPressed.DOWN || (FlxG.keys.pressed.DOWN && canHold))
				changeAnimOrPos(0, 1 * mult);

			if (FlxG.keys.justPressed.G)
				setGhostAnim(char.animation.name);

			if (FlxG.keys.justPressed.H)
				guideChar.visible = !guideChar.visible;
		}

		if (dragMousePos != null)
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			var delta = mousePos - dragMousePos;
			var offset = switch (dragging)
			{
				case 1: charInfo.positionOffset;
				case 2: charInfo.cameraOffset;
				default: char.getCurAnim().offset;
			};
			var mult = dragging == 0 ? -1 : 1;
			offset[0] = dragPositionOffset[0] + FlxMath.roundDecimal(delta.x, 2) * mult;
			offset[1] = dragPositionOffset[1] + FlxMath.roundDecimal(delta.y, 2) * mult;

			if (dragging == 0)
				setAnimOffset(offset[0], offset[1]);
			else
			{
				if (dragging == 1)
				{
					char.updatePosition();
					ghostChar.updatePosition();
				}
				updateCamIndicator();
			}

			if (FlxG.mouse.released)
			{
				dragMousePos = null;
				dragPositionOffset = null;
			}

			mousePos.put();
			delta.put();
		}

		if (FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			if (FlxG.mouse.overlaps(camIndicator))
			{
				dragMousePos = mousePos;
				dragPositionOffset = charInfo.cameraOffset.copy();
				dragging = 2;
			}
			else if (FlxG.mouse.overlaps(char))
			{
				dragMousePos = mousePos;
				if (currentTool.value == POSITION)
				{
					dragPositionOffset = charInfo.positionOffset.copy();
					dragging = 1;
				}
				else
				{
					dragPositionOffset = char.getCurAnim().offset.copy();
					dragging = 0;
				}
			}
			else
				mousePos.put();
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
		toolPanel.update(elapsed);
		uiGroup.update(elapsed);
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

		var newText = 'Frame: ' + curFrame + ' / ' + numFrames;
		if (char.animation.paused)
			newText += '\n(Paused)';

		if (animText.text != newText)
			animText.text = newText;
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

	function changeAnimOffset(xChange:Int, yChange:Int = 0)
	{
		var curAnim = char.getCurAnim();
		setAnimOffset(curAnim.offset[0] + xChange, curAnim.offset[1] + yChange);

		timeSinceLastChange = 0;
	}

	function setAnimOffset(x:Float = 0, y:Float = 0)
	{
		var curAnim = char.getCurAnim();
		curAnim.offset[0] = x;
		curAnim.offset[1] = y;

		var offset = char.offsets.get(curAnim.name);
		offset[0] = x;
		offset[1] = y;
		var ghostOffset = ghostChar.offsets.get(curAnim.name);
		ghostOffset[0] = offset[0];
		ghostOffset[1] = offset[1];

		char.updateOffset();
		if (ghostChar.animation.name == char.animation.name)
			ghostChar.updateOffset();
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

	function changeAnimOrPos(xChange:Int, yChange:Int = 0)
	{
		if (FlxG.keys.pressed.ALT)
			changePositionOffset(xChange, yChange);
		else
			changeAnimOffset(xChange, yChange);
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
		charInfo.save(Path.join([charInfo.directory, charInfo.name + '.json']));
	}

	function updateCamIndicator()
	{
		camIndicator.setPosition(char.x + (char.startWidth / 2) + charInfo.cameraOffset[0], char.y + (char.startHeight / 2) + charInfo.cameraOffset[1]);
	}

	function saveFrame(filename:String)
	{
		var frame = char.frame;
		if (frame == null)
			return;

		var bytes = char.pixels.encode(frame.frame.copyToFlash(), new PNGEncoderOptions());
		File.saveBytes(filename, bytes);
		System.openFile(filename);
		notificationManager.showNotification('Image successfully saved!', SUCCESS);
	}
}

enum abstract MoveTool(String) from String to String
{
	var ANIM = 'Animation Offset';
	var POSITION = 'Position Offset';

	public function getIndex()
	{
		return switch (this)
		{
			case POSITION: 1;
			default: 0;
		}
	}

	public static function fromIndex(index:Int)
	{
		return switch (index)
		{
			case 1: POSITION;
			default: ANIM;
		}
	}
}
