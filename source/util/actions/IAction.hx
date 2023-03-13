package util.actions;

interface IAction
{
	var type:String;
	private var manager:ActionManager;
	function perform():Void;
	function undo():Void;
}
