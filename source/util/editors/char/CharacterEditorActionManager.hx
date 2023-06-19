package util.editors.char;

import data.char.CharacterInfo;
import flixel.util.FlxColor;
import states.editors.CharacterEditorState;
import util.editors.actions.ActionManager;
import util.editors.actions.IAction;

class CharacterEditorActionManager extends ActionManager
{
	public static inline var CHANGE_IMAGE:String = 'change-image';
	public static inline var CHANGE_DANCE_ANIMS:String = 'change-dance-anims';
	public static inline var CHANGE_FLIP_X:String = 'change-flip-x';
	public static inline var CHANGE_SCALE:String = 'change-scale';
	public static inline var CHANGE_ANTIALIASING:String = 'change-antialiasing';
	public static inline var CHANGE_POSITION_OFFSET:String = 'change-position-offset';
	public static inline var CHANGE_CAMERA_OFFSET:String = 'change-camera-offset';
	public static inline var CHANGE_ICON:String = 'change-icon';
	public static inline var CHANGE_HEALTH_COLOR:String = 'change-health-color';
	public static inline var CHANGE_LOOP_ANIMS:String = 'change-loop-anims';
	public static inline var CHANGE_LOOP_POINT:String = 'change-loop-point';
	public static inline var CHANGE_FLIP_ALL:String = 'change-flip-all';
	public static inline var CHANGE_CONSTANT_LOOPING:String = 'change-constant-looping';
	public static inline var ADD_ANIM:String = 'add-anim';
	public static inline var REMOVE_ANIM:String = 'remove-anim';
	public static inline var CHANGE_ANIM_NAME:String = 'change-anim-name';
	public static inline var CHANGE_ANIM_ATLAS_NAME:String = 'change-anim-atlas-name';
	public static inline var CHANGE_ANIM_INDICES:String = 'change-anim-indices';
	public static inline var CHANGE_ANIM_FPS:String = 'change-anim-fps';
	public static inline var CHANGE_ANIM_LOOP:String = 'change-anim-loop';
	public static inline var CHANGE_ANIM_FLIP_X:String = 'change-anim-flip-x';
	public static inline var CHANGE_ANIM_FLIP_Y:String = 'change-anim-flip-y';
	public static inline var CHANGE_ANIM_OFFSET:String = 'change-anim-offset';
	public static inline var CHANGE_ANIM_NEXT:String = 'change-anim-next';
}

class ActionChangeImage implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_IMAGE;

	var state:CharacterEditorState;
	var image:String;
	var lastImage:String;

	public function new(state:CharacterEditorState, image:String)
	{
		this.state = state;
		this.image = image;
	}

	public function perform()
	{
		lastImage = state.charInfo.image;
		state.charInfo.image = image;

		state.char.reloadImage();
		state.ghostChar.reloadImage();
		state.updateCamIndicator();

		state.actionManager.triggerEvent(type, {
			image: image
		});
	}

	public function undo()
	{
		new ActionChangeImage(state, lastImage).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeDanceAnims implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_DANCE_ANIMS;

	var state:CharacterEditorState;
	var danceAnims:Array<String>;
	var lastAnims:Array<String>;

	public function new(state:CharacterEditorState, danceAnims:Array<String>)
	{
		this.state = state;
		this.danceAnims = danceAnims;
	}

	public function perform()
	{
		// is this too much copying???
		lastAnims = state.charInfo.danceAnims.copy();
		state.charInfo.danceAnims = danceAnims.copy();

		state.char.danceAnims = danceAnims.copy();
		state.ghostChar.danceAnims = danceAnims.copy();
		state.updateCharSize();

		state.actionManager.triggerEvent(type, {
			danceAnims: danceAnims
		});
	}

	public function undo()
	{
		new ActionChangeDanceAnims(state, lastAnims).perform();
	}

	public function destroy()
	{
		state = null;
		danceAnims = null;
		lastAnims = null;
	}
}

class ActionChangeFlipX implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_FLIP_X;

	var state:CharacterEditorState;
	var flipX:Bool;
	var lastFlipX:Bool;

	public function new(state:CharacterEditorState, flipX:Bool)
	{
		this.state = state;
		this.flipX = flipX;
	}

	public function perform()
	{
		lastFlipX = state.charInfo.flipX;
		state.charInfo.flipX = flipX;

		state.char.flipX = state.ghostChar.flipX = flipX;

		state.actionManager.triggerEvent(type, {
			flipX: flipX
		});
	}

	public function undo()
	{
		new ActionChangeFlipX(state, lastFlipX).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeScale implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_SCALE;

	var state:CharacterEditorState;
	var scale:Float;
	var lastScale:Float;

	public function new(state:CharacterEditorState, scale:Float)
	{
		this.state = state;
		this.scale = scale;
	}

	public function perform()
	{
		lastScale = state.charInfo.scale;
		state.charInfo.scale = scale;

		state.char.scale.set(scale, scale);
		state.ghostChar.scale.copyFrom(state.char.scale);
		state.char.frameOffsetScale = scale;
		state.updateCharSize();

		state.actionManager.triggerEvent(type, {
			scale: scale
		});
	}

	public function undo()
	{
		new ActionChangeScale(state, lastScale).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeAntialiasing implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANTIALIASING;

	var state:CharacterEditorState;
	var antialiasing:Bool;
	var lastAntialiasing:Bool;

	public function new(state:CharacterEditorState, antialiasing:Bool)
	{
		this.state = state;
		this.antialiasing = antialiasing;
	}

	public function perform()
	{
		lastAntialiasing = state.charInfo.antialiasing;
		state.charInfo.antialiasing = antialiasing;

		state.char.antialiasing = state.ghostChar.antialiasing = antialiasing;

		state.actionManager.triggerEvent(type, {
			antialiasing: antialiasing
		});
	}

	public function undo()
	{
		new ActionChangeAntialiasing(state, lastAntialiasing).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangePositionOffset implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_POSITION_OFFSET;

	var state:CharacterEditorState;
	var offset:Array<Float>;
	var lastOffset:Array<Float>;

	public function new(state:CharacterEditorState, offset:Array<Float>, lastOffset:Array<Float>)
	{
		this.state = state;
		this.offset = offset;
		this.lastOffset = lastOffset;
	}

	public function perform()
	{
		state.charInfo.positionOffset[0] = offset[0];
		state.charInfo.positionOffset[1] = offset[1];

		state.updatePosition();

		state.actionManager.triggerEvent(type, {
			offset: offset
		});
	}

	public function undo()
	{
		new ActionChangePositionOffset(state, lastOffset, offset).perform();
	}

	public function destroy()
	{
		state = null;
		offset = null;
		lastOffset = null;
	}
}

class ActionChangeCameraOffset implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_CAMERA_OFFSET;

	var state:CharacterEditorState;
	var offset:Array<Float>;
	var lastOffset:Array<Float>;

	public function new(state:CharacterEditorState, offset:Array<Float>, lastOffset:Array<Float>)
	{
		this.state = state;
		this.offset = offset;
		this.lastOffset = lastOffset;
	}

	public function perform()
	{
		state.charInfo.cameraOffset[0] = offset[0];
		state.charInfo.cameraOffset[1] = offset[1];

		state.updateCamIndicator();

		state.actionManager.triggerEvent(type, {
			offset: offset
		});
	}

	public function undo()
	{
		new ActionChangeCameraOffset(state, lastOffset, offset).perform();
	}

	public function destroy()
	{
		state = null;
		offset = null;
		lastOffset = null;
	}
}

class ActionChangeIcon implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ICON;

	var state:CharacterEditorState;
	var icon:String;
	var lastIcon:String;

	public function new(state:CharacterEditorState, icon:String)
	{
		this.state = state;
		this.icon = icon;
	}

	public function perform()
	{
		lastIcon = state.charInfo.healthIcon;
		state.charInfo.healthIcon = icon;

		state.updateIcon();

		state.actionManager.triggerEvent(type, {
			icon: icon
		});
	}

	public function undo()
	{
		new ActionChangeIcon(state, lastIcon).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeHealthColor implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_HEALTH_COLOR;

	var state:CharacterEditorState;
	var color:FlxColor;
	var lastColor:FlxColor;

	public function new(state:CharacterEditorState, color:FlxColor)
	{
		this.state = state;
		this.color = color;
	}

	public function perform()
	{
		lastColor = state.charInfo.healthColors;
		state.charInfo.healthColors = color;

		state.updateBar();

		state.actionManager.triggerEvent(type, {
			color: color
		});
	}

	public function undo()
	{
		new ActionChangeHealthColor(state, lastColor).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeLoopAnims implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_LOOP_ANIMS;

	var state:CharacterEditorState;
	var loopAnims:Bool;
	var lastLoopAnims:Bool;

	public function new(state:CharacterEditorState, loopAnims:Bool)
	{
		this.state = state;
		this.loopAnims = loopAnims;
	}

	public function perform()
	{
		lastLoopAnims = state.charInfo.loopAnimsOnHold;
		state.charInfo.loopAnimsOnHold = loopAnims;

		state.actionManager.triggerEvent(type, {
			loopAnims: loopAnims
		});
	}

	public function undo()
	{
		new ActionChangeLoopAnims(state, lastLoopAnims).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeLoopPoint implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_LOOP_POINT;

	var state:CharacterEditorState;
	var loopPoint:Int;
	var lastLoopPoint:Int;

	public function new(state:CharacterEditorState, loopPoint:Int)
	{
		this.state = state;
		this.loopPoint = loopPoint;
	}

	public function perform()
	{
		lastLoopPoint = state.charInfo.holdLoopPoint;
		state.charInfo.holdLoopPoint = loopPoint;

		state.actionManager.triggerEvent(type, {
			loopPoint: loopPoint
		});
	}

	public function undo()
	{
		new ActionChangeLoopPoint(state, lastLoopPoint).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeFlipAll implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_FLIP_ALL;

	var state:CharacterEditorState;
	var flipAll:Bool;
	var lastFlipAll:Bool;

	public function new(state:CharacterEditorState, flipAll:Bool)
	{
		this.state = state;
		this.flipAll = flipAll;
	}

	public function perform()
	{
		lastFlipAll = state.charInfo.flipAll;
		state.charInfo.flipAll = flipAll;

		state.actionManager.triggerEvent(type, {
			flipAll: flipAll
		});
	}

	public function undo()
	{
		new ActionChangeFlipAll(state, lastFlipAll).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionChangeConstantLooping implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_CONSTANT_LOOPING;

	var state:CharacterEditorState;
	var constantLooping:Bool;
	var lastConstantLooping:Bool;

	public function new(state:CharacterEditorState, constantLooping:Bool)
	{
		this.state = state;
		this.constantLooping = constantLooping;
	}

	public function perform()
	{
		lastConstantLooping = state.charInfo.constantLooping;
		state.charInfo.constantLooping = constantLooping;

		state.actionManager.triggerEvent(type, {
			constantLooping: constantLooping
		});
	}

	public function undo()
	{
		new ActionChangeConstantLooping(state, lastConstantLooping).perform();
	}

	public function destroy()
	{
		state = null;
	}
}

class ActionAddAnim implements IAction
{
	public var type = CharacterEditorActionManager.ADD_ANIM;

	var state:CharacterEditorState;
	var anim:AnimInfo;

	public function new(state:CharacterEditorState, anim:AnimInfo)
	{
		this.state = state;
		this.anim = anim;
	}

	public function perform()
	{
		state.charInfo.anims.push(anim);
		state.addAnim(anim);

		state.actionManager.triggerEvent(type, {
			anim: anim
		});
	}

	public function undo()
	{
		new ActionRemoveAnim(state, anim).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionRemoveAnim implements IAction
{
	public var type = CharacterEditorActionManager.REMOVE_ANIM;

	var state:CharacterEditorState;
	var anim:AnimInfo;

	public function new(state:CharacterEditorState, anim:AnimInfo)
	{
		this.state = state;
		this.anim = anim;
	}

	public function perform()
	{
		state.charInfo.anims.remove(anim);

		var newAnim = state.charInfo.anims.length > 0 ? state.charInfo.anims[0].name : '';
		if (state.char.animation.name == anim.name)
			state.changeAnim(newAnim);
		if (state.ghostChar.animation.name == anim.name)
			state.ghostChar.playAnim(newAnim);
		state.char.animation.remove(anim.name);
		state.ghostChar.animation.remove(anim.name);

		state.actionManager.triggerEvent(type, {
			anim: anim
		});
	}

	public function undo()
	{
		new ActionAddAnim(state, anim).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimName implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_NAME;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var name:String;
	var lastName:String;

	public function new(state:CharacterEditorState, anim:AnimInfo, name:String)
	{
		this.state = state;
		this.anim = anim;
		this.name = name;
	}

	public function perform()
	{
		lastName = anim.name;
		anim.name = name;

		if (state.curAnim == lastName)
			state.curAnim = name;
		if (state.char.animation.exists(lastName))
		{
			state.char.animation.rename(lastName, name);
			state.char.offsets.set(name, state.char.offsets.get(lastName));
			state.char.offsets.remove(lastName);
			if (state.char.animation.name == null || state.char.animation.name == lastName)
				state.char.playAnim(name, true);

			state.ghostChar.animation.rename(lastName, name);
			state.ghostChar.offsets.set(name, state.ghostChar.offsets.get(lastName));
			state.ghostChar.offsets.remove(lastName);
			if (state.ghostChar.animation.name == lastName)
				state.ghostChar.playAnim(name, true);
		}

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastName: lastName
		});
	}

	public function undo()
	{
		new ActionChangeAnimName(state, anim, lastName).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimAtlasName implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_ATLAS_NAME;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var name:String;
	var lastName:String;

	public function new(state:CharacterEditorState, anim:AnimInfo, name:String)
	{
		this.state = state;
		this.anim = anim;
		this.name = name;
	}

	public function perform()
	{
		lastName = anim.atlasName;
		anim.atlasName = name;

		var lastAnim = state.curAnim;
		var lastGhostAnim = state.ghostChar.animation.name;
		state.updateAnim(anim);
		if (lastAnim == null || lastAnim == anim.name)
			state.changeAnim(anim.name);
		if (lastGhostAnim == anim.name)
			state.ghostChar.playAnim(lastGhostAnim, true);

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastName: lastName
		});
	}

	public function undo()
	{
		new ActionChangeAnimAtlasName(state, anim, lastName).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimIndices implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_INDICES;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var indices:Array<Int>;
	var lastIndices:Array<Int>;

	public function new(state:CharacterEditorState, anim:AnimInfo, indices:Array<Int>)
	{
		this.state = state;
		this.anim = anim;
		this.indices = indices;
	}

	public function perform()
	{
		lastIndices = anim.indices.copy();
		anim.indices = indices.copy();

		state.updateAnim(anim);
		if (state.char.animation.name == null || state.curAnim == anim.name)
			state.char.playAnim(anim.name, true);
		if (state.ghostChar.animation.name == anim.name)
			state.ghostChar.playAnim(anim.name, true);

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastIndices: lastIndices
		});
	}

	public function undo()
	{
		new ActionChangeAnimIndices(state, anim, lastIndices).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
		indices = null;
		lastIndices = null;
	}
}

class ActionChangeAnimFPS implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_FPS;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var fps:Float;
	var lastFPS:Float;

	public function new(state:CharacterEditorState, anim:AnimInfo, fps:Float)
	{
		this.state = state;
		this.anim = anim;
		this.fps = fps;
	}

	public function perform()
	{
		lastFPS = anim.fps;
		anim.fps = fps;

		if (state.char.animation.exists(anim.name))
		{
			state.char.animation.getByName(anim.name).frameRate = fps;
			state.ghostChar.animation.getByName(anim.name).frameRate = fps;
		}

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastFPS: lastFPS
		});
	}

	public function undo()
	{
		new ActionChangeAnimFPS(state, anim, lastFPS).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimLoop implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_LOOP;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var loop:Bool;
	var lastLoop:Bool;

	public function new(state:CharacterEditorState, anim:AnimInfo, loop:Bool)
	{
		this.state = state;
		this.anim = anim;
		this.loop = loop;
	}

	public function perform()
	{
		lastLoop = anim.loop;
		anim.loop = loop;

		if (state.char.animation.exists(anim.name))
		{
			state.char.animation.getByName(anim.name).looped = loop;
			state.ghostChar.animation.getByName(anim.name).looped = loop;
		}

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastLoop: lastLoop
		});
	}

	public function undo()
	{
		new ActionChangeAnimLoop(state, anim, lastLoop).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimFlipX implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_FLIP_X;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var flip:Bool;
	var lastFlip:Bool;

	public function new(state:CharacterEditorState, anim:AnimInfo, flip:Bool)
	{
		this.state = state;
		this.anim = anim;
		this.flip = flip;
	}

	public function perform()
	{
		lastFlip = anim.flipX;
		anim.flipX = flip;

		if (state.char.animation.exists(anim.name))
		{
			state.char.animation.getByName(anim.name).flipX = flip;
			state.ghostChar.animation.getByName(anim.name).flipX = flip;
		}

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastFlip: lastFlip
		});
	}

	public function undo()
	{
		new ActionChangeAnimFlipX(state, anim, lastFlip).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimFlipY implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_FLIP_Y;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var flip:Bool;
	var lastFlip:Bool;

	public function new(state:CharacterEditorState, anim:AnimInfo, flip:Bool)
	{
		this.state = state;
		this.anim = anim;
		this.flip = flip;
	}

	public function perform()
	{
		lastFlip = anim.flipY;
		anim.flipY = flip;

		if (state.char.animation.exists(anim.name))
		{
			state.char.animation.getByName(anim.name).flipY = flip;
			state.ghostChar.animation.getByName(anim.name).flipY = flip;
		}

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastFlip: lastFlip
		});
	}

	public function undo()
	{
		new ActionChangeAnimFlipY(state, anim, lastFlip).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}

class ActionChangeAnimOffset implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_OFFSET;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var offset:Array<Float>;
	var lastOffset:Array<Float>;

	public function new(state:CharacterEditorState, anim:AnimInfo, offset:Array<Float>, lastOffset:Array<Float>)
	{
		this.state = state;
		this.anim = anim;
		this.offset = offset;
		this.lastOffset = lastOffset;
	}

	public function perform()
	{
		anim.offset[0] = offset[0];
		anim.offset[1] = offset[1];

		state.setAnimOffset(anim, anim.offset[0], anim.offset[1]);

		state.actionManager.triggerEvent(type, {
			anim: anim
		});
	}

	public function undo()
	{
		new ActionChangeAnimOffset(state, anim, lastOffset, offset).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
		offset = null;
		lastOffset = null;
	}
}

class ActionChangeAnimNext implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_ANIM_NEXT;

	var state:CharacterEditorState;
	var anim:AnimInfo;
	var nextAnim:String;
	var lastAnim:String;

	public function new(state:CharacterEditorState, anim:AnimInfo, nextAnim:String)
	{
		this.state = state;
		this.anim = anim;
		this.nextAnim = nextAnim;
	}

	public function perform()
	{
		lastAnim = anim.nextAnim;
		anim.nextAnim = nextAnim;

		state.actionManager.triggerEvent(type, {
			anim: anim,
			lastAnim: lastAnim
		});
	}

	public function undo()
	{
		new ActionChangeAnimNext(state, anim, lastAnim).perform();
	}

	public function destroy()
	{
		state = null;
		anim = null;
	}
}
