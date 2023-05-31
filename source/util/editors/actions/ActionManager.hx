package util.editors.actions;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

class ActionManager implements IFlxDestroyable
{
	public static final BATCH:String = 'batch';

	public var undoStack:Array<IAction> = [];
	public var redoStack:Array<IAction> = [];
	public var lastSaveAction:IAction;
	public var hasUnsavedChanges(get, never):Bool;
	public var onEvent:FlxTypedSignal<String->Dynamic->Void> = new FlxTypedSignal();

	public function new() {}

	public function perform(action:IAction)
	{
		action.perform();
		undoStack.unshift(action);
		redoStack.resize(0);
	}

	public function performBatch(actions:Array<IAction>)
	{
		perform(new ActionBatch(actions));
	}

	public function undo()
	{
		if (undoStack.length == 0)
			return;

		var action = undoStack.shift();
		action.undo();

		redoStack.unshift(action);
	}

	public function redo()
	{
		if (redoStack.length == 0)
			return;

		var action = redoStack.shift();
		action.perform();

		undoStack.unshift(action);
	}

	public function triggerEvent(type:String, args:Dynamic)
	{
		onEvent.dispatch(type, args);
	}

	public function destroy()
	{
		undoStack = FlxDestroyUtil.destroyArray(undoStack);
		redoStack = FlxDestroyUtil.destroyArray(redoStack);
		lastSaveAction = null;
		FlxDestroyUtil.destroy(onEvent);
	}

	function get_hasUnsavedChanges()
	{
		return (undoStack.length > 0 && undoStack[0] != lastSaveAction) || (undoStack.length == 0 && lastSaveAction != null);
	}
}
