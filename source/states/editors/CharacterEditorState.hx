package states.editors;

import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import lime.system.System;
import openfl.display.PNGEncoderOptions;
import sprites.AnimatedSprite.AnimData;
import sprites.game.BGSprite;
import sprites.game.Character;
import subStates.editors.char.CharacterEditorSavePrompt;
import sys.FileSystem;
import sys.io.File;
import ui.editors.NotificationManager;
import ui.editors.char.CharacterEditorAnimPanel;
import ui.editors.char.CharacterEditorEditPanel;
import ui.editors.char.CharacterEditorToolPanel;
import ui.game.HealthBar;
import util.DiscordClient;
import util.MemoryUtil;
import util.bindable.Bindable;
import util.editors.char.CharacterEditorActionManager;

using StringTools;

class CharacterEditorState extends FNFState
{
	static var CHAR_X:Int = 100;
	static var CHAR_Y:Int = 100;
	static var globalInfo:CharacterInfo;
	
	public var currentTool:Bindable<MoveTool> = new Bindable(ANIM);
	public var info:CharacterInfo;
	public var char:Character;
	public var ghostChar:Character;
	public var actionManager:CharacterEditorActionManager;
	public var notificationManager:NotificationManager;
	public var guideChar:Character;
	public var healthBar:HealthBar;
	public var curAnim:String;
	
	var camPos:FlxObject;
	var animText:FlxText;
	var timeSinceLastChange:Float = 0;
	var ghostAnim:String;
	var dragMousePos:FlxPoint;
	var dragPositionOffset:Array<Float>;
	var uiGroup:FlxGroup;
	var camIndicator:FlxSprite;
	var dragging:Int = 0;
	var toolPanel:CharacterEditorToolPanel;
	var animPanel:CharacterEditorAnimPanel;
	var editPanel:CharacterEditorEditPanel;
	var savePrompt:CharacterEditorSavePrompt;
	var changed:Bool = false;
	
	public function new(?info:CharacterInfo)
	{
		super();
		if (globalInfo == null)
			globalInfo = CharacterInfo.loadCharacterFromName('fnf:bf');
			
		if (info == null)
			info = globalInfo;
		else
			globalInfo = info;
		this.info = info;
		
		persistentUpdate = true;
		checkObjects = true;
		destroySubStates = false;
	}
	
	override function destroy()
	{
		super.destroy();
		info = null;
		char = null;
		camPos = null;
		animText = null;
		ghostChar = null;
		dragMousePos = FlxDestroyUtil.put(dragMousePos);
		guideChar = null;
		notificationManager = null;
		uiGroup = null;
		camIndicator = null;
		toolPanel = null;
		animPanel = null;
		editPanel = null;
		actionManager = FlxDestroyUtil.destroy(actionManager);
		savePrompt = FlxDestroyUtil.destroy(savePrompt);
	}
	
	override function create()
	{
		updatePresence();
		
		actionManager = new CharacterEditorActionManager();
		
		var bg = new BGSprite('fnf:stages/stage/stageback', -600, -200, 0.9, 0.9);
		add(bg);
		
		var stageFront = new BGSprite('fnf:stages/stage/stagefront', -650, 600, 0.9, 0.9);
		stageFront.scale.set(1.1, 1.1);
		stageFront.updateHitbox();
		add(stageFront);
		
		guideChar = new Character(CHAR_X, CHAR_Y, CharacterInfo.loadCharacterFromName('fnf:dad'));
		guideChar.color = 0xFF886666;
		guideChar.alpha = 0.6;
		guideChar.debugMode = true;
		add(guideChar);
		
		ghostChar = new Character(CHAR_X, CHAR_Y, info);
		ghostChar.visible = false;
		ghostChar.color = 0xFF666688;
		ghostChar.alpha = 0.6;
		ghostChar.debugMode = true;
		add(ghostChar);
		
		char = new Character(CHAR_X, CHAR_Y, info);
		char.alpha = 0.85;
		char.debugMode = true;
		add(char);
		
		camIndicator = new FlxSprite(0, 0, Paths.getImage('editors/cross'));
		camIndicator.scale.set(2, 2);
		camIndicator.updateHitbox();
		add(camIndicator);
		
		animText = new FlxText(5, 0, FlxG.width - 10);
		animText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);
		
		healthBar = new HealthBar(null, info);
		healthBar.x = (FlxG.width - healthBar.bar.width) / 2;
		healthBar.bar.value = 50;
		add(healthBar);
		
		uiGroup = new FlxTypedGroup();
		
		toolPanel = new CharacterEditorToolPanel(this);
		uiGroup.add(toolPanel);
		
		animPanel = new CharacterEditorAnimPanel(this);
		uiGroup.add(animPanel);
		
		editPanel = new CharacterEditorEditPanel(this);
		uiGroup.add(editPanel);
		
		add(uiGroup);
		
		savePrompt = new CharacterEditorSavePrompt(onSavePrompt);
		
		notificationManager = new NotificationManager();
		add(notificationManager);
		
		camPos = new FlxObject();
		add(camPos);
		FlxG.camera.follow(camPos);
		
		reloadinfo();
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		uiGroup.update(elapsed);
		
		handleInput(elapsed);
		
		camPos.update(elapsed);
		ghostChar.update(elapsed);
		char.update(elapsed);
		healthBar.icon.update(elapsed);
		notificationManager.update(elapsed);
		
		updateAnimText();
		
		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;
	}
	
	override function openSubState(subState)
	{
		persistentUpdate = false;
		super.openSubState(subState);
	}
	
	function handleInput(elapsed:Float)
	{
		var allowInput = checkAllowInput();
		
		if (allowInput && FlxG.keys.anyPressed([I, J, K, L]))
		{
			var angle = FlxG.keys.angleFromKeys([I, J, K, L]);
			camPos.velocity.setPolarDegrees(900, angle);
		}
		else
			camPos.velocity.set();
			
		timeSinceLastChange += elapsed;
		
		if (!allowInput)
			return;
			
		var hasAnim = char.animation.curAnim != null && char.animation.curAnim.frames != null;
		
		if (FlxG.keys.justPressed.R)
			resetCamPos();
			
		if (hasAnim)
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
			if (char.animation.curAnim.numFrames > 1)
			{
				if (char.animation.curAnim.paused)
				{
					if (FlxG.keys.justPressed.COMMA)
						changeFrameIndex(-1);
					if (FlxG.keys.justPressed.PERIOD)
						changeFrameIndex(1);
				}
				if (FlxG.keys.justPressed.HOME)
				{
					char.animation.curAnim.curFrame = 0;
					if (char.animation.finished)
						char.animation.curAnim.play();
				}
				if (FlxG.keys.justPressed.END)
					char.animation.curAnim.curFrame = char.animation.curAnim.numFrames - 1;
			}
			
			if (FlxG.keys.justPressed.G)
				setGhostAnim(char.animation.name);
		}
		
		var canHold = timeSinceLastChange >= 0.1;
		var mult = FlxG.keys.pressed.SHIFT ? 10 : 1;
		if (FlxG.keys.justPressed.LEFT || (FlxG.keys.pressed.LEFT && canHold))
			changeAnimOrPos(-1 * mult, 0, hasAnim);
		if (FlxG.keys.justPressed.RIGHT || (FlxG.keys.pressed.RIGHT && canHold))
			changeAnimOrPos(1 * mult, 0, hasAnim);
		if (FlxG.keys.justPressed.UP || (FlxG.keys.pressed.UP && canHold))
			changeAnimOrPos(0, -1 * mult, hasAnim);
		if (FlxG.keys.justPressed.DOWN || (FlxG.keys.pressed.DOWN && canHold))
			changeAnimOrPos(0, 1 * mult, hasAnim);
			
		if (FlxG.keys.justPressed.H)
			guideChar.visible = !guideChar.visible;
			
		if (FlxG.keys.justPressed.ONE)
			currentTool.value = ANIM;
		if (FlxG.keys.justPressed.TWO)
			currentTool.value = POSITION;
			
		if (dragMousePos != null)
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			var delta = mousePos - dragMousePos;
			var offset = switch (dragging)
			{
				case 1: info.positionOffset;
				case 2: info.cameraOffset;
				default: info.getAnim(curAnim).offset;
			};
			var mult = dragging == 0 ? -1 : 1;
			offset[0] = dragPositionOffset[0] + FlxMath.roundDecimal(delta.x, 2) * mult;
			offset[1] = dragPositionOffset[1] + FlxMath.roundDecimal(delta.y, 2) * mult;
			
			switch (dragging)
			{
				case 1:
					updatePosition();
					editPanel.updatePositionOffset();
				case 2:
					updateCamIndicator();
					editPanel.updateCameraOffset();
				default:
					setAnimOffset(info.getAnim(curAnim), offset[0], offset[1]);
			}
			
			if (FlxG.mouse.released)
			{
				if (offset[0] != dragPositionOffset[0] || offset[1] != dragPositionOffset[1])
				{
					switch (dragging)
					{
						case 1:
							actionManager.perform(new ActionChangePositionOffset(this, offset.copy(), dragPositionOffset));
						case 2:
							actionManager.perform(new ActionChangeCameraOffset(this, offset.copy(), dragPositionOffset));
						default:
							actionManager.perform(new ActionChangeAnimOffset(this, info.getAnim(curAnim), offset.copy(), dragPositionOffset));
					}
				}
				dragMousePos = null;
				dragPositionOffset = null;
			}
			
			mousePos.put();
			delta.put();
		}
		
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(uiGroup))
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			if (healthBar.icon.pixelsOverlapPoint(mousePos, 1))
			{
				var anim = healthBar.icon.animation;
				var nextAnim = switch (anim.name)
				{
					case 'normal':
						'losing';
					case 'losing':
						if (anim.exists('winning')) 'winning'; else 'normal';
					default: 'normal';
				}
				if (anim.exists(nextAnim))
				{
					healthBar.icon.playAnim(nextAnim);
					healthBar.updateIconPos();
				}
			}
			else if (FlxG.mouse.overlaps(camIndicator))
			{
				dragMousePos = mousePos;
				dragPositionOffset = info.cameraOffset.copy();
				dragging = 2;
			}
			else if (char.pixelsOverlapPoint(mousePos, 1))
			{
				if (currentTool.value == POSITION)
				{
					dragMousePos = mousePos;
					dragPositionOffset = info.positionOffset.copy();
					dragging = 1;
				}
				else if (hasAnim)
				{
					dragMousePos = mousePos;
					dragPositionOffset = info.getAnim(curAnim).offset.copy();
					dragging = 0;
				}
				else
					mousePos.put();
			}
			else
				mousePos.put();
		}
		
		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.Z)
				actionManager.undo();
			if (FlxG.keys.justPressed.Y)
				actionManager.redo();
			if (FlxG.keys.justPressed.S)
				save();
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
			leaveEditor();
	}
	
	function resetCamPos()
	{
		camPos.setPosition(camIndicator.x + (camIndicator.width / 2), camIndicator.y + (camIndicator.height / 2));
	}
	
	function updateAnimText()
	{
		var numFrames = 0;
		if (char.animation.curAnim != null)
			numFrames = char.animation.curAnim.numFrames;
		var curFrame = numFrames > 0 ? char.animation.curAnim.curFrame + 1 : 0;
		
		var newText = 'Frame: ' + curFrame + ' / ' + numFrames;
		if (char.animation.paused)
			newText += '\n(Paused)';
			
		if (animText.text != newText)
			animText.text = newText;
	}
	
	public function changeAnim(anim:String)
	{
		curAnim = anim;
		
		var paused = char.animation.paused;
		
		char.playAnim(anim, true);
		
		if (paused)
			char.animation.pause();
			
		editPanel.updateCurAnim();
	}
	
	function changeFrameIndex(change:Int)
	{
		char.animation.curAnim.curFrame = FlxMath.wrapInt(char.animation.curAnim.curFrame + change, 0, char.animation.curAnim.numFrames - 1);
	}
	
	function changeAnimOffset(xChange:Int, yChange:Int = 0)
	{
		var curAnim = info.getAnim(curAnim);
		setAnimOffset(curAnim, curAnim.offset[0] + xChange, curAnim.offset[1] + yChange);
		
		timeSinceLastChange = 0;
		changed = true;
	}
	
	public function setAnimOffset(anim:AnimInfo, x:Float = 0, y:Float = 0)
	{
		anim.offset[0] = x;
		anim.offset[1] = y;
		
		var offset = char.offsets.get(anim.name);
		offset[0] = x;
		offset[1] = y;
		var ghostOffset = ghostChar.offsets.get(anim.name);
		ghostOffset[0] = offset[0];
		ghostOffset[1] = offset[1];
		
		if (char.animation.name == anim.name)
			char.updateOffset();
		if (ghostChar.animation.name == anim.name)
			ghostChar.updateOffset();
			
		editPanel.updateOffset();
	}
	
	function changePositionOffset(xChange:Int, yChange:Int = 0)
	{
		info.positionOffset[0] += xChange;
		info.positionOffset[1] += yChange;
		
		updatePosition();
		
		editPanel.updatePositionOffset();
		
		timeSinceLastChange = 0;
		changed = true;
	}
	
	public function updatePosition()
	{
		char.updatePosition();
		ghostChar.updatePosition();
		
		updateCamIndicator();
	}
	
	function changeAnimOrPos(xChange:Int, yChange:Int = 0, hasAnim:Bool = true)
	{
		if (currentTool.value == POSITION)
			changePositionOffset(xChange, yChange);
		else if (hasAnim)
			changeAnimOffset(-xChange, -yChange);
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
	
	public function save(notif:Bool = true, forceSave:Bool = false)
	{
		if (!actionManager.hasUnsavedChanges && !forceSave && !changed)
			return;
			
		info.save(Path.join([info.directory, info.name + '.json']));
		
		actionManager.lastSaveAction = actionManager.undoStack[0];
		changed = false;
		
		if (notif)
			notificationManager.showNotification('Character successfully saved!', SUCCESS);
	}
	
	public function updateCamIndicator()
	{
		camIndicator.setPosition(char.x + (char.startWidth / 2) + info.cameraOffset[0], char.y + (char.startHeight / 2) + info.cameraOffset[1]);
	}
	
	public function saveFrame(filename:String)
	{
		var frame = char.frame;
		if (frame == null)
			return;
			
		var bytes = frame.parent.bitmap.encode(frame.frame.copyToFlash(), new PNGEncoderOptions());
		var path = 'frames/$filename';
		FileSystem.createDirectory('frames/');
		File.saveBytes(path, bytes);
		System.openFile(path);
		notificationManager.showNotification('Image successfully saved!', SUCCESS);
	}
	
	public function reloadinfo()
	{
		var oldGraphic = char.graphic;
		
		ghostChar.info = info;
		char.info = info;
		
		if (oldGraphic != null && oldGraphic.useCount <= 0)
			FlxG.bitmap.remove(oldGraphic);
			
		updateCamIndicator();
		updateAnimText();
		updateIcon();
		updateBar();
		
		resetCamPos();
		FlxG.camera.snapToTarget();
		
		if (char.animation.name != null)
			curAnim = char.animation.name;
			
		animPanel.reloadDropdown();
		editPanel.updateChar();
	}
	
	public function updateAnim(anim:AnimInfo)
	{
		var data:AnimData = {
			name: anim.name,
			atlasName: anim.atlasName,
			indices: anim.indices.copy(),
			fps: anim.fps,
			loop: anim.loop,
			flipX: anim.flipX,
			flipY: anim.flipY,
			offset: anim.offset
		};
		char.animation.remove(anim.name);
		char.addAnim(data);
		ghostChar.animation.remove(anim.name);
		ghostChar.addAnim(data);
		
		updateCharSize();
	}
	
	public function addAnim(anim:AnimInfo)
	{
		var data:AnimData = {
			name: anim.name,
			atlasName: anim.atlasName,
			indices: anim.indices.copy(),
			fps: anim.fps,
			loop: anim.loop,
			flipX: anim.flipX,
			flipY: anim.flipY,
			offset: anim.offset
		};
		char.addAnim(data);
		ghostChar.addAnim(data);
		
		updateCharSize();
		changeAnim(anim.name);
	}
	
	public function updateCharSize()
	{
		char.updateSize();
		ghostChar.updateSize();
		updateCamIndicator();
	}
	
	public function updateBar()
	{
		healthBar.bar.createFilledBar(info.healthColors.getDarkened(0.5), info.healthColors);
		healthBar.bar.updateBar();
	}
	
	public function updateIcon()
	{
		var iconName = info.healthIcon;
		if (!iconName.contains(':'))
			iconName = info.mod + ':' + iconName;
		healthBar.icon.icon = iconName;
		healthBar.updateIconPos();
	}
	
	public function updatePresence()
	{
		DiscordClient.changePresence("Character: " + info.name, "Character Editor");
	}
	
	function leaveEditor()
	{
		if (actionManager.hasUnsavedChanges)
			openSubState(savePrompt);
		else
			onSavePrompt('No');
	}
	
	function onSavePrompt(option:String)
	{
		if (option != 'Cancel')
		{
			if (option == 'Yes')
				save();
			persistentUpdate = false;
			FlxG.switchState(new ToolboxState());
		}
	}
	
	public function setInfo(info:CharacterInfo)
	{
		actionManager.reset();
		globalInfo = this.info = info;
		reloadinfo();
		updatePresence();
		MemoryUtil.clearMinor();
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
