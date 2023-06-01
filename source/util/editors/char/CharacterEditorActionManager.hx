package util.editors.char;

import data.char.CharacterInfo;
import states.editors.CharacterEditorState;
import util.editors.actions.ActionManager;
import util.editors.actions.IAction;

class CharacterEditorActionManager extends ActionManager
{
	public static inline var CHANGE_IMAGE:String = 'change-image';
	public static inline var ADD_ANIM:String = 'add-anim';
	public static inline var REMOVE_ANIM:String = 'remove-anim';
	public static inline var CHANGE_ANIM_NAME:String = 'change-anim-name';
	public static inline var CHANGE_ANIM_ATLAS_NAME:String = 'change-anim-atlas-name';
	public static inline var CHANGE_ANIM_INDICES:String = 'change-anim-indices';
	public static inline var CHANGE_ANIM_FPS:String = 'change-anim-fps';
	public static inline var CHANGE_ANIM_LOOP:String = 'change-anim-loop';
	public static inline var CHANGE_ANIM_OFFSET:String = 'change-anim-offset';
	public static inline var CHANGE_ANIM_NEXT:String = 'change-anim-next';
	public static inline var CHANGE_POSITION_OFFSET:String = 'change-position-offset';
	public static inline var CHANGE_CAMERA_OFFSET:String = 'change-camera-offset';
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

		if (state.char.animation.name == anim.name)
			state.changeAnim(state.charInfo.danceAnims[0]);
		if (state.ghostChar.animation.name == anim.name)
			state.ghostChar.animation.play(state.charInfo.danceAnims[0]);
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

		if (state.char.animation.exists(lastName))
		{
			state.char.animation.rename(lastName, name);
			if (state.char.animation.name == lastName)
				state.char.playAnim(name, true, false, state.char.animation.curAnim.curFrame);

			state.ghostChar.animation.rename(lastName, name);
			if (state.ghostChar.animation.name == lastName)
				state.ghostChar.playAnim(name, true, false, state.ghostChar.animation.curAnim.curFrame);
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

		state.updateAnim(anim);

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

class ActionChangePositionOffset implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_POSITION_OFFSET;

	var state:CharacterEditorState;
	var info:CharacterInfo;
	var offset:Array<Float>;
	var lastOffset:Array<Float>;

	public function new(state:CharacterEditorState, info:CharacterInfo, offset:Array<Float>, lastOffset:Array<Float>)
	{
		this.state = state;
		this.info = info;
		this.offset = offset;
		this.lastOffset = lastOffset;
	}

	public function perform()
	{
		info.positionOffset[0] = offset[0];
		info.positionOffset[1] = offset[1];

		state.updatePosition();

		state.actionManager.triggerEvent(type, {
			offset: offset
		});
	}

	public function undo()
	{
		new ActionChangePositionOffset(state, info, lastOffset, offset).perform();
	}

	public function destroy()
	{
		state = null;
		info = null;
		offset = null;
		lastOffset = null;
	}
}

class ActionChangeCameraOffset implements IAction
{
	public var type = CharacterEditorActionManager.CHANGE_CAMERA_OFFSET;

	var state:CharacterEditorState;
	var info:CharacterInfo;
	var offset:Array<Float>;
	var lastOffset:Array<Float>;

	public function new(state:CharacterEditorState, info:CharacterInfo, offset:Array<Float>, lastOffset:Array<Float>)
	{
		this.state = state;
		this.info = info;
		this.offset = offset;
		this.lastOffset = lastOffset;
	}

	public function perform()
	{
		info.cameraOffset[0] = offset[0];
		info.cameraOffset[1] = offset[1];

		state.updateCamIndicator();

		state.actionManager.triggerEvent(type, {
			offset: offset
		});
	}

	public function undo()
	{
		new ActionChangeCameraOffset(state, info, lastOffset, offset).perform();
	}

	public function destroy()
	{
		state = null;
		info = null;
		offset = null;
		lastOffset = null;
	}
}
