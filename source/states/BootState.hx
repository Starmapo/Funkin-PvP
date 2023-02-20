package states;

import data.PlayerSettings;
import data.song.Song;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class BootState extends FlxTransitionableState
{
	override function create()
	{
		FlxG.autoPause = false; // don't pause when focus is lost by default
		FlxG.fixedTimestep = false; // allow elapsed time to be variable
		FlxG.game.focusLostFramerate = 60; // 60 fps instead of 10 when focus is lost
		FlxG.mouse.useSystemCursor = true; // use system cursor instead of HaxeFlixel one
		FlxG.mouse.visible = false; // hide mouse by default
		FlxGraphic.defaultPersist = true; // graphics won't be cleared by default
		// create custom transitions
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, -1), null);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, 1), null);
		WindowsAPI.setWindowToDarkMode();

		PlayerSettings.init();

		FlxG.switchState(new BasicPlayState(Song.loadSong('mods/fnf/songs/Bopeebo/Hard.json')));

		super.create();
	}
}
