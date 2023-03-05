package states;

import data.PlayerSettings;
import data.Settings;
import data.song.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import util.WindowsAPI;

class BootState extends FNFState
{
	override function create()
	{
		FlxG.autoPause = false; // don't pause when focus is lost by default
		FlxG.fixedTimestep = false; // allow elapsed time to be variable
		FlxG.game.focusLostFramerate = 60; // 60 fps instead of 10 when focus is lost
		FlxG.mouse.useSystemCursor = true; // use system cursor instead of HaxeFlixel one
		FlxG.mouse.visible = false; // hide mouse by default
		FlxG.sound.muteKeys = [ZERO]; // remove numpad zero from mute keys
		FlxGraphic.defaultPersist = true; // graphics won't be cleared by default
		FlxSprite.defaultAntialiasing = true; // set antialiasing to true by default
		// create custom transitions
		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, -1), null);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(0, 1), null);
		WindowsAPI.setWindowToDarkMode(); // change window to dark mode

		Settings.loadData(); // load settings
		PlayerSettings.init(); // initialize players and controls

		var song = Song.loadSong('mods/Hard.json');
		var averageDifficulty = (song.solveDifficulty(false).overallDifficulty + song.solveDifficulty(true).overallDifficulty) / 2;
		trace('Average difficulty: $averageDifficulty');

		FlxG.switchState(new TitleState()); // switch to the title screen

		super.create();
	}
}
