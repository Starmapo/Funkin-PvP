package backend.game;

import backend.settings.PlayerConfig;
import backend.structures.song.NoteInfo;
import backend.structures.song.Song;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import objects.game.Note;
import objects.game.Playfield;

/**
	Handles notes for gameplay.
**/
class NoteManager extends FlxBasic
{
	/**
		The opacity for the strums when it's break time.
	**/
	static final BREAK_ALPHA:Float = 0.2;
	
	/**
		The next note to hit. Can be `null`.
	**/
	public var nextNote(get, never):NoteInfo;
	
	/**
		The current timing position of the song, taking the global offset into account.
	**/
	public var currentAudioPosition(get, never):Float;
	
	/**
		The current visual position of the song.
	**/
	public var currentVisualPosition(get, never):Float;
	
	/**
		The current track position of the song, taking scroll velocities into account.
	**/
	public var currentTrackPosition:Float = 0;
	
	/**
		The player configuration for this manager.
	**/
	public var config:PlayerConfig;
	
	/**
		Gets the current scroll speed, taking the playback rate into account.
	**/
	public var scrollSpeed(get, never):Float;
	
	/**
		List of lanes containing notes yet to be spawned.
	**/
	public var noteQueueLanes:Array<Array<NoteInfo>> = [];
	
	/**
		List of lanes containing currently active notes.
	**/
	public var activeNoteLanes:Array<Array<Note>> = [];
	
	/**
		List of lanes containing dead notes (those which were missed).
	**/
	public var deadNoteLanes:Array<Array<Note>> = [];
	
	/**
		List of lanes containing currently held long notes.
	**/
	public var heldLongNoteLanes:Array<Array<Note>> = [];
	
	/**
		Whether the song is currently on break (no notes nearby).
	**/
	public var onBreak(get, never):Bool;
	
	/**
		The current opacity for the notes. Modified when it's break time.
	**/
	public var alpha:Float = 1;
	
	var playfield:Playfield;
	var player:Int;
	var createObjectPositionTreshold:Float;
	var recycleObjectPositionTreshold:Float;
	var createObjectTimeTreshold:Float;
	var objectPositionMagnitude:Int = 3000;
	var velocityPositionMarkers:Array<Float> = [];
	var currentSvIndex:Int = 0;
	var initialPoolSizePerLane:Int = 2;
	var autoplay(get, never):Bool;
	var song(get, never):Song;
	var scoreProcessor(get, never):ScoreProcessor;
	var ruleset(get, never):GameplayRuleset;
	
	public function new(playfield:Playfield, player:Int)
	{
		super();
		this.playfield = playfield;
		this.player = player;
		config = Settings.playerConfigs[player];
		
		updatePoolingPositions();
		initializePositionMarkers();
		updateCurrentTrackPosition();
		initializeInfoPools();
		initializeObjectPool();
		
		if (Settings.breakTransparency && onBreak)
		{
			alpha = BREAK_ALPHA;
			playfield.alpha = alpha;
		}
		
		active = false;
	}
	
	override function update(elapsed:Float)
	{
		updateCurrentTrackPosition();
		updateAlpha(elapsed);
		updateAndScoreActiveObjects(elapsed);
		updateAndScoreHeldObjects(elapsed);
		updateDeadObjects(elapsed);
	}
	
	override function draw()
	{
		var groups = [activeNoteLanes, deadNoteLanes, heldLongNoteLanes];
		for (lanes in groups)
		{
			for (lane in lanes)
			{
				for (note in lane)
				{
					if (note != null && note.exists && note.visible)
					{
						var lastAlpha = note.alpha;
						note.alpha *= alpha;
						
						note.cameras = cameras;
						note.draw();
						
						note.alpha = lastAlpha;
					}
				}
			}
		}
	}
	
	override function destroy()
	{
		config = null;
		noteQueueLanes = null;
		activeNoteLanes = destroyLanes(activeNoteLanes);
		deadNoteLanes = destroyLanes(deadNoteLanes);
		heldLongNoteLanes = destroyLanes(heldLongNoteLanes);
		playfield = null;
		velocityPositionMarkers = null;
		super.destroy();
	}
	
	/**
		Gets the track position of a time point, taking scroll velocities into account.
	**/
	public function getPositionFromTime(time:Float)
	{
		var i = 0;
		while (i < song.scrollVelocities.length)
		{
			if (time < song.scrollVelocities[i].startTime)
				break;
				
			i++;
		}
		
		return getPositionFromTimeIndex(time, i);
	}
	
	/**
		Returns the scroll velocity direction changes during `startTime` and `endTime`.
	**/
	public function getSVDirectionChanges(startTime:Float, endTime:Float)
	{
		var changes:Array<SVDirectionChange> = [];
		if (Settings.noSliderVelocity)
			return changes;
			
		var i = 0;
		while (i < song.scrollVelocities.length)
		{
			if (startTime < song.scrollVelocities[i].startTime)
				break;
				
			i++;
		}
		
		var forward:Bool;
		if (i == 0)
			forward = song.initialScrollVelocity >= 0;
		else
			forward = song.scrollVelocities[i - 1].multipliers[player] >= 0;
			
		while (i < song.scrollVelocities.length && endTime >= song.scrollVelocities[i].startTime)
		{
			var multiplier = song.scrollVelocities[i].multipliers[player];
			if (multiplier == 0)
			{
				i++;
				continue;
			}
			
			if (forward == (multiplier > 0))
			{
				i++;
				continue;
			}
			
			forward = multiplier > 0;
			changes.push({
				startTime: song.scrollVelocities[i].startTime,
				position: velocityPositionMarkers[i]
			});
			
			i++;
		}
		
		return changes;
	}
	
	/**
		Returns if the scroll velocity at `time` is going backwards.
	**/
	public function isSVNegative(time:Float)
	{
		if (Settings.noSliderVelocity)
			return false;
			
		var i = 0;
		while (i < song.scrollVelocities.length)
		{
			if (time < song.scrollVelocities[i].startTime)
				break;
				
			i++;
		}
		
		i--;
		
		while (i >= 0)
		{
			if (song.scrollVelocities[i].multipliers[player] != 0)
				break;
				
			i--;
		}
		
		if (i == -1)
			return song.initialScrollVelocity < 0;
			
		return song.scrollVelocities[i].multipliers[player] < 0;
	}
	
	/**
		Gets the closest note that can be hit in a lane.
	**/
	public function getClosestTap(lane:Int)
	{
		return activeNoteLanes[lane].length > 0 ? activeNoteLanes[lane][0] : null;
	}
	
	/**
		Gets the closest long note that can be released in a lane.
	**/
	public function getClosestRelease(lane:Int)
	{
		return heldLongNoteLanes[lane].length > 0 ? heldLongNoteLanes[lane][0] : null;
	}
	
	/**
		Updates the current track position.
	**/
	public function updateCurrentTrackPosition()
	{
		while (currentSvIndex < song.scrollVelocities.length && currentVisualPosition >= song.scrollVelocities[currentSvIndex].startTime)
			currentSvIndex++;
		currentTrackPosition = getPositionFromTimeIndex(currentVisualPosition, currentSvIndex);
	}
	
	/**
		Creates a new note from a `NoteInfo`.
	**/
	public function createPoolObject(info:NoteInfo)
	{
		var note = new Note(info, this, playfield, playfield.noteSkin);
		activeNoteLanes[info.playerLane].push(note);
		ruleset.noteSpawned.dispatch(note);
	}
	
	/**
		Kills a note and adds it to the dead lanes.
	**/
	public function killPoolObject(note:Note)
	{
		note.killNote();
		deadNoteLanes[note.info.playerLane].push(note);
	}
	
	/**
		Kills a long note and adds it to the dead lanes.
	**/
	public function killHoldPoolObject(note:Note, setTint:Bool = true)
	{
		note.initialTrackPosition = getPositionFromTime(currentVisualPosition);
		note.currentlyBeingHeld = false;
		note.updateLongNoteSize(currentTrackPosition, currentVisualPosition);
		
		if (setTint)
			note.killNote();
			
		deadNoteLanes[note.info.playerLane].push(note);
	}
	
	/**
		Recycles a note for the next note in the lane if possible, or destroys it if not.
	**/
	public function recyclePoolObject(note:Note)
	{
		note.currentlyBeingHeld = false;
		var lane = noteQueueLanes[note.info.playerLane];
		if (lane.length > 0)
		{
			var info = lane.shift();
			note.initializeObject(info);
			activeNoteLanes[info.playerLane].push(note);
			ruleset.noteSpawned.dispatch(note);
		}
		else
			note.destroy();
	}
	
	/**
		Changes a note to being currently held.
	**/
	public function changePoolObjectStatusToHeld(note:Note)
	{
		heldLongNoteLanes[note.info.playerLane].push(note);
		note.currentlyBeingHeld = true;
		note.head.visible = false;
	}
	
	/**
		Handles skipping forward in the song.
	**/
	public function handleSkip()
	{
		currentSvIndex = 0;
		updateCurrentTrackPosition();
		resetNoteInfo();
		update(0);
	}
	
	function getPositionFromTimeIndex(time:Float, index:Int)
	{
		if (Settings.noSliderVelocity)
			return time;
			
		if (index == 0)
			return time * song.initialScrollVelocity;
			
		index--;
		
		var curPos = velocityPositionMarkers[index];
		curPos += ((time - song.scrollVelocities[index].startTime) * song.scrollVelocities[index].multipliers[player]);
		return curPos;
	}
	
	function updatePoolingPositions()
	{
		recycleObjectPositionTreshold = objectPositionMagnitude / scrollSpeed;
		createObjectPositionTreshold = objectPositionMagnitude / scrollSpeed;
		createObjectTimeTreshold = objectPositionMagnitude / scrollSpeed;
	}
	
	function initializePositionMarkers()
	{
		if (song.scrollVelocities.length == 0)
			return;
			
		var position = song.scrollVelocities[0].startTime * song.initialScrollVelocity;
		velocityPositionMarkers.push(position);
		for (i in 1...song.scrollVelocities.length)
		{
			position += ((song.scrollVelocities[i].startTime - song.scrollVelocities[i - 1].startTime) * song.scrollVelocities[i - 1].multipliers[player]);
			velocityPositionMarkers.push(position);
		}
	}
	
	function initializeInfoPools(skipObjects:Bool = false)
	{
		for (i in 0...4)
		{
			noteQueueLanes.push([]);
			activeNoteLanes.push([]);
			deadNoteLanes.push([]);
			heldLongNoteLanes.push([]);
		}
		
		for (note in song.notes)
		{
			if (note.player != player)
				continue;
				
			if (skipObjects)
			{
				if (!note.isLongNote)
				{
					if (note.startTime < currentAudioPosition)
						continue;
				}
				else
				{
					if (note.startTime < currentAudioPosition && note.endTime < currentAudioPosition)
						continue;
				}
			}
			
			noteQueueLanes[note.playerLane].push(note);
		}
	}
	
	function initializeObjectPool()
	{
		for (lane in noteQueueLanes)
		{
			var i = 0;
			while (i < initialPoolSizePerLane && lane.length > 0)
			{
				createPoolObject(lane.shift());
				i++;
			}
		}
	}
	
	function destroyLanes<T:IFlxDestroyable>(array:Array<Array<T>>):Array<Array<T>>
	{
		if (array != null)
		{
			for (lane in array)
				FlxDestroyUtil.destroyArray(lane);
		}
		return null;
	}
	
	function updateAndScoreActiveObjects(elapsed:Float)
	{
		for (lane in noteQueueLanes)
		{
			while (lane.length > 0
				&& ((Math.abs(currentTrackPosition - getPositionFromTime(lane[0].startTime)) < createObjectPositionTreshold)
					|| (lane[0].startTime - currentAudioPosition < createObjectTimeTreshold)))
				createPoolObject(lane.shift());
		}
		
		scoreActiveObjects();
		
		for (lane in activeNoteLanes)
		{
			for (note in lane)
			{
				note.updateSpritePositions(currentTrackPosition, currentVisualPosition);
				if (note.isOnScreen(cameras[0]))
					note.update(elapsed);
			}
		}
	}
	
	function scoreActiveObjects()
	{
		if (autoplay)
			return;
			
		for (lane in activeNoteLanes)
		{
			while (lane.length > 0 && currentAudioPosition > lane[0].info.startTime + scoreProcessor.judgementWindow[Judgement.SHIT])
			{
				var note = lane.shift();
				
				var stat = new HitStat(MISS, NONE, note.info, note.info.startTime, MISS, FlxMath.MIN_VALUE_FLOAT, scoreProcessor.accuracy,
					scoreProcessor.health);
				scoreProcessor.stats.push(stat);
				
				scoreProcessor.registerScore(MISS);
				
				ruleset.noteReleaseMissed.dispatch(note);
				
				if (note.info.isLongNote)
				{
					killPoolObject(note);
					scoreProcessor.registerScore(MISS, true);
					scoreProcessor.stats.push(stat);
				}
				else
					killPoolObject(note);
			}
		}
	}
	
	function updateAndScoreHeldObjects(elapsed:Float)
	{
		scoreHeldObjects();
		
		for (lane in heldLongNoteLanes)
		{
			for (note in lane)
			{
				note.updateSpritePositions(currentTrackPosition, currentVisualPosition);
				note.update(elapsed);
			}
		}
	}
	
	function scoreHeldObjects()
	{
		if (autoplay)
			return;
			
		var window = scoreProcessor.judgementWindow[Judgement.SHIT] * scoreProcessor.windowReleaseMultiplier[Judgement.SHIT];
		
		for (lane in heldLongNoteLanes)
		{
			while (lane.length > 0 && currentAudioPosition > lane[0].info.endTime + window)
			{
				var note = lane.shift();
				
				var missedReleaseJudgement = Judgement.BAD;
				
				var stat = new HitStat(MISS, NONE, note.info, note.info.endTime, missedReleaseJudgement, FlxMath.MIN_VALUE_INT, scoreProcessor.accuracy,
					scoreProcessor.health);
				scoreProcessor.stats.push(stat);
				
				scoreProcessor.registerScore(missedReleaseJudgement, true);
				
				recyclePoolObject(note);
			}
		}
	}
	
	function updateDeadObjects(elapsed:Float)
	{
		for (lane in deadNoteLanes)
		{
			while (lane.length > 0 && Math.abs(currentTrackPosition - lane[0].latestTrackPosition) > recycleObjectPositionTreshold)
				recyclePoolObject(lane.shift());
		}
		
		for (lane in deadNoteLanes)
		{
			for (note in lane)
			{
				note.updateSpritePositions(currentTrackPosition, currentVisualPosition);
				if (note.isOnScreen(cameras[0]))
					note.update(elapsed);
			}
		}
	}
	
	function updateAlpha(elapsed:Float)
	{
		if (!Settings.breakTransparency)
			return;
			
		if (onBreak && alpha > BREAK_ALPHA)
		{
			alpha -= elapsed * 3;
			if (alpha < BREAK_ALPHA)
				alpha = BREAK_ALPHA;
		}
		else if (!onBreak && alpha < 1)
		{
			alpha += elapsed * 3;
			if (alpha > 1)
				alpha = 1;
		}
		playfield.alpha = alpha;
	}
	
	function resetNoteInfo()
	{
		for (lane in noteQueueLanes)
		{
			var i = lane.length - 1;
			while (i >= 0)
			{
				var note = lane[i];
				if (note.maxTime < currentAudioPosition)
					lane.remove(note);
				i--;
			}
		}
		
		var queues = [activeNoteLanes, heldLongNoteLanes, deadNoteLanes];
		for (queue in queues)
		{
			for (lane in queue)
			{
				var i = 0;
				while (i < lane.length)
				{
					var note = lane[i];
					if (note.info.maxTime < currentAudioPosition)
					{
						lane.remove(note);
						recyclePoolObject(note);
					}
					else
						i++;
				}
			}
		}
	}
	
	function get_scrollSpeed()
	{
		return config.scrollSpeed / GameplayGlobals.playbackRate;
	}
	
	function get_autoplay()
	{
		return playfield.inputManager.autoplay;
	}
	
	function get_nextNote()
	{
		var nextNote:NoteInfo = null;
		var earliestNoteTime = FlxMath.MAX_VALUE_FLOAT;
		
		for (notesInLane in activeNoteLanes)
		{
			if (notesInLane.length == 0)
				continue;
				
			var note = notesInLane[0];
			if (note.info.startTime >= earliestNoteTime)
				continue;
				
			earliestNoteTime = note.info.startTime;
			nextNote = note.info;
		}
		
		for (notesInLane in noteQueueLanes)
		{
			if (notesInLane.length == 0)
				continue;
				
			var note = notesInLane[0];
			if (note.startTime >= earliestNoteTime)
				continue;
				
			earliestNoteTime = note.startTime;
			nextNote = note;
		}
		
		return nextNote;
	}
	
	function get_onBreak()
	{
		for (laneNotes in heldLongNoteLanes)
		{
			if (laneNotes.length > 0)
				return false;
		}
		
		if (nextNote == null)
			return true;
			
		return (nextNote.startTime - currentAudioPosition >= 5000 * GameplayGlobals.playbackRate);
	}
	
	function get_song()
	{
		return ruleset.song;
	}
	
	function get_scoreProcessor()
	{
		return playfield.scoreProcessor;
	}
	
	function get_ruleset()
	{
		return playfield.ruleset;
	}
	
	function get_currentAudioPosition()
	{
		return ruleset.timing.audioPosition;
	}
	
	function get_currentVisualPosition()
	{
		return ruleset.timing.audioPosition;
	}
}
