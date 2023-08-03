package backend.actions;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

interface IAction extends IFlxDestroyable
{
	var type:String;
	function perform():Void;
	function undo():Void;
}
