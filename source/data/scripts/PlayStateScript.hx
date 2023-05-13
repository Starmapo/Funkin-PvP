package data.scripts;

import data.song.NoteInfo;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import states.PlayState;
import ui.game.Note;

class PlayStateScript extends Script
{
	var state:PlayState;

	public function new(state:PlayState, path:String, mod:String)
	{
		this.state = state;
		super(path, mod);
	}

	override function destroy()
	{
		state = null;
		super.destroy();
	}

	override function setStartingVariables()
	{
		super.setStartingVariables();

		setVariable("state", state);
		setVariable("opponent", state.opponent);
		setVariable("bf", state.bf);
		setVariable("gf", state.gf);
		setVariable("camFollow", state.camFollow);
		setVariable("ruleset", state.ruleset);
		setVariable("timing", state.timing);
		setVariable("camHUD", state.camHUD);
		setVariable("songInst", state.songInst);
		setVariable("songVocals", state.songVocals);
		setVariable("statsDisplay", state.statsDisplay);
		setVariable("judgementDisplay", state.judgementDisplay);
		setVariable("songInfoDisplay", state.songInfoDisplay);
		setVariable("lyricsDisplay", state.lyricsDisplay);
		setVariable("healthBars", state.healthBars);

		setVariable("add", state.add);
		setVariable("insert", state.insert);
		setVariable("remove", state.remove);

		setVariable("getOrder", function(obj:FlxBasic)
		{
			return state.members.indexOf(obj);
		});
		setVariable("setOrder", function(obj:FlxBasic, index:Int)
		{
			state.remove(obj, true);
			return state.insert(index, obj);
		});
		setVariable("addBehindChars", function(obj:FlxBasic)
		{
			var index = FlxMath.minInt(FlxMath.minInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index, obj);
		});
		setVariable("addOverChars", function(obj:FlxBasic)
		{
			var index = FlxMath.maxInt(FlxMath.maxInt(state.members.indexOf(state.gf), state.members.indexOf(state.opponent)),
				state.members.indexOf(state.bf));
			return state.insert(index + 1, obj);
		});
		setVariable("addBehindOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent), obj);
		});
		setVariable("addBehindBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf), obj);
		});
		setVariable("addBehindGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf), obj);
		});
		setVariable("addOverOpponent", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.opponent) + 1, obj);
		});
		setVariable("addOverBF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.bf) + 1, obj);
		});
		setVariable("addOverGF", function(obj:FlxBasic)
		{
			return state.insert(state.members.indexOf(state.gf) + 1, obj);
		});
		setVariable("getPlayerCharacter", function(player:Int = 0)
		{
			return state.getPlayerCharacter(player);
		});
		setVariable("getNoteCharacter", function(note:Note)
		{
			return state.getNoteCharacter(note);
		});
		setVariable("getCurrentNotes", function()
		{
			var notes:Array<Note> = [];
			for (manager in state.ruleset.noteManagers)
			{
				pushLaneNotes(notes, manager.activeNoteLanes);
				pushLaneNotes(notes, manager.heldLongNoteLanes);
				pushLaneNotes(notes, manager.deadNoteLanes);
			}
			return notes;
		});
		setVariable("getActiveNotes", function()
		{
			var notes:Array<Note> = [];
			for (manager in state.ruleset.noteManagers)
				pushLaneNotes(notes, manager.activeNoteLanes);
			return notes;
		});
		setVariable("getHeldNotes", function()
		{
			var notes:Array<Note> = [];
			for (manager in state.ruleset.noteManagers)
				pushLaneNotes(notes, manager.heldLongNoteLanes);
			return notes;
		});
		setVariable("getDeadNotes", function()
		{
			var notes:Array<Note> = [];
			for (manager in state.ruleset.noteManagers)
				pushLaneNotes(notes, manager.deadNoteLanes);
			return notes;
		});
		setVariable("getQueueNotes", function()
		{
			var notes:Array<NoteInfo> = [];
			for (manager in state.ruleset.noteManagers)
				pushLaneNotes(notes, manager.noteQueueLanes);
			return notes;
		});
	}

	override function onError(message:String)
	{
		state.notificationManager.showNotification(message, ERROR);
	}

	function pushLaneNotes<T:Any>(to:Array<T>, array:Array<Array<T>>)
	{
		for (lane in array)
		{
			for (note in lane)
				to.push(note);
		}
	}
}
