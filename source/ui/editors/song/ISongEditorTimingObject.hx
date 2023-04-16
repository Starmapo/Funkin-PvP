package ui.editors.song;

import data.song.ITimingObject;
import flixel.FlxCamera;
import flixel.FlxSprite;

interface ISongEditorTimingObject extends IFlxSprite
{
	var info:ITimingObject;
	var selectionSprite:FlxSprite;
	function isOnScreen(?camera:FlxCamera):Bool;
	function isHovered():Bool;
	function updatePosition():Void;
}
