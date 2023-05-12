package util.editors.actions;

class ActionBatch implements IAction
{
	public var type:String = ActionManager.BATCH;

	var actions:Array<IAction>;

	public function new(actions:Array<IAction>)
	{
		this.actions = actions;
	}

	public function perform()
	{
		for (action in actions)
			action.perform();
	}

	public function undo()
	{
		var i = actions.length - 1;
		while (i >= 0)
		{
			actions[i].undo();
			i--;
		}
	}

	public function destroy()
	{
		actions = null;
	}
}
