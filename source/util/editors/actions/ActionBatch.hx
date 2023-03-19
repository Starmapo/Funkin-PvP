package util.editors.actions;

class ActionBatch implements IAction
{
	public var type:String = 'batch';

	var manager:ActionManager;
	var actions:Array<IAction>;

	public function new(manager:ActionManager, actions:Array<IAction>)
	{
		this.manager = manager;
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
}
