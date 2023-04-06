package ui.editors.song;

import flixel.FlxSprite.IFlxSprite;
import data.song.ITimingObject;

interface ISongEditorTimingObject extends IFlxSprite
{
	var info:ITimingObject;
}
