package util.editors.actions;

interface IAction
{
	var type:String;
	private var manager:ActionManager;
	function perform():Void;
	function undo():Void;
}
