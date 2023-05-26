package data.game;

import data.song.NoteInfo;
import data.song.Song;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import ui.game.Note;

class NoteManager extends FlxBasic
{
	static var breakAlpha:Float = 0.2;

	public var nextNote(get, never):NoteInfo;
	public var currentAudioPosition:Float = 0;
	public var currentVisualPosition:Float = 0;
	public var currentTrackPosition:Float = 0;
	public var config:PlayerConfig;
	public var scrollSpeed(get, never):Float;
	public var noteQueueLanes:Array<Array<NoteInfo>> = [];
	public var activeNoteLanes:Array<Array<Note>> = [];
	public var deadNoteLanes:Array<Array<Note>> = [];
	public var heldLongNoteLanes:Array<Array<Note>> = [];
	public var onBreak(get, never):Bool;
	public var alpha:Float = 1;

	var ruleset:GameplayRuleset;
	var song:Song;
	var player:Int;
	var createObjectPositionTreshold:Float;
	var recycleObjectPositionTreshold:Float;
	var createObjectTimeTreshold:Float;
	var objectPositionMagnitude:Int = 3000;
	var velocityPositionMarkers:Array<Float> = [];
	var currentSvIndex:Int = 0;
	var initialPoolSizePerLane:Int = 2;
	var autoplay(get, never):Bool;

	public function new(ruleset:GameplayRuleset, song:Song, player:Int)
	{
		super();
		this.ruleset = ruleset;
		this.song = song;
		this.player = player;
		config = Settings.playerConfigs[player];

		updatePoolingPositions();
		initializePositionMarkers();
		updateCurrentTrackPosition();
		initializeInfoPools();
		initializeObjectPool();

		if (Settings.breakTransparency && onBreak)
		{
			alpha = breakAlpha;
			ruleset.playfields[player].alpha = alpha;
		}
	}

	override function update(elapsed:Float)
	{
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
					if (note != null && note.exists && note.canDraw())
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
		noteQueueLanes = destroyLanes(noteQueueLanes);
		activeNoteLanes = destroyLanes(activeNoteLanes);
		deadNoteLanes = destroyLanes(deadNoteLanes);
		heldLongNoteLanes = destroyLanes(heldLongNoteLanes);
		ruleset = null;
		song = null;
		velocityPositionMarkers = null;
		super.destroy();
	}

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

	public function getPositionFromTimeIndex(time:Float, index:Int)
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

	public function getClosestTap(lane:Int)
	{
		return activeNoteLanes[lane].length > 0 ? activeNoteLanes[lane][0] : null;
	}

	public function getClosestRelease(lane:Int)
	{
		return heldLongNoteLanes[lane].length > 0 ? heldLongNoteLanes[lane][0] : null;
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

	public function updateCurrentTrackPosition()
	{
		currentAudioPosition = currentVisualPosition = ruleset.timing.audioPosition;
		while (currentSvIndex < song.scrollVelocities.length && currentVisualPosition >= song.scrollVelocities[currentSvIndex].startTime)
			currentSvIndex++;
		currentTrackPosition = getPositionFromTimeIndex(currentVisualPosition, currentSvIndex);
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

	public function createPoolObject(info:NoteInfo)
	{
		var note = new Note(info, this, ruleset.playfields[player]);
		activeNoteLanes[info.playerLane].push(note);
		ruleset.noteSpawned.dispatch(note);
	}

	public function killPoolObject(note:Note)
	{
		note.killNote();
		deadNoteLanes[note.info.playerLane].push(note);
	}

	public function killHoldPoolObject(note:Note, setTint:Bool = true)
	{
		note.initialTrackPosition = getPositionFromTime(currentVisualPosition);
		note.currentlyBeingHeld = false;
		note.updateLongNoteSize(currentTrackPosition, currentVisualPosition);

		if (setTint)
			note.killNote();

		deadNoteLanes[note.info.playerLane].push(note);
	}

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

	public function changePoolObjectStatusToHeld(note:Note)
	{
		heldLongNoteLanes[note.info.playerLane].push(note);
		note.currentlyBeingHeld = true;
		note.head.visible = false;
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
			while (lane.length > 0
				&& currentAudioPosition > lane[0].info.startTime + ruleset.scoreProcessors[player].judgementWindow[Judgement.SHIT])
			{
				var note = lane.shift();

				var stat = new HitStat(MISS, NONE, note.info, note.info.startTime, MISS, FlxMath.MIN_VALUE_FLOAT, ruleset.scoreProcessors[player].accuracy,
					ruleset.scoreProcessors[player].health);
				ruleset.scoreProcessors[player].stats.push(stat);

				ruleset.scoreProcessors[player].registerScore(MISS);

				ruleset.noteReleaseMissed.dispatch(note);

				if (note.info.isLongNote)
				{
					killPoolObject(note);
					ruleset.scoreProcessors[player].registerScore(MISS, true);
					ruleset.scoreProcessors[player].stats.push(stat);
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

		var window = ruleset.scoreProcessors[player].judgementWindow[Judgement.SHIT] * ruleset.scoreProcessors[player].windowReleaseMultiplier[Judgement.SHIT];

		for (lane in heldLongNoteLanes)
		{
			while (lane.length > 0 && currentAudioPosition > lane[0].info.endTime + window)
			{
				var note = lane.shift();

				var missedReleaseJudgement = Judgement.BAD;

				var stat = new HitStat(MISS, NONE, note.info, note.info.endTime, missedReleaseJudgement, FlxMath.MIN_VALUE_INT,
					ruleset.scoreProcessors[player].accuracy, ruleset.scoreProcessors[player].health);
				ruleset.scoreProcessors[player].stats.push(stat);

				ruleset.scoreProcessors[player].registerScore(missedReleaseJudgement, true);

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

		if (onBreak && alpha > breakAlpha)
		{
			alpha -= elapsed * 3;
			if (alpha < breakAlpha)
				alpha = breakAlpha;
		}
		else if (!onBreak && alpha < 1)
		{
			alpha += elapsed * 3;
			if (alpha > 1)
				alpha = 1;
		}
		ruleset.playfields[player].alpha = alpha;
	}

	function get_scrollSpeed()
	{
		return config.scrollSpeed / Settings.playbackRate;
	}

	function get_autoplay()
	{
		return ruleset.inputManagers[player].autoplay;
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

		return (nextNote.startTime - currentAudioPosition >= 5000 * Settings.playbackRate);
	}
}
