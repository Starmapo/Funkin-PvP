package util.editors.actions;

interface IAction
{
	var type:String;
	function perform():Void;
	function undo():Void;
}
