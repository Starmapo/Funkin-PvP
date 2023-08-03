package objects.editors.song;

import backend.structures.song.ITimingObject;
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
