package data.game;

import data.song.NoteInfo;
import data.song.Song;
import flixel.FlxG;
import flixel.math.FlxMath;
import ui.game.Note;

class NoteManager
{
	public var nextNote:NoteInfo;
	public var currentAudioPosition:Float = 0;
	public var currentVisualPosition:Float = 0;
	public var currentTrackPosition:Float = 0;
	public var config:PlayerConfig;
	public var scrollSpeed(get, never):Float;
	public var noteQueueLanes:Array<Array<NoteInfo>> = [];
	public var activeNoteLanes:Array<Array<Note>> = [];
	public var deadNoteLanes:Array<Array<Note>> = [];
	public var heldLongNoteLanes:Array<Array<Note>> = [];

	var ruleset:GameplayRuleset;
	var song:Song;
	var player:Int;
	var playbackRate:Float;
	var noSliderVelocity:Bool;
	var songLength:Float;
	var createObjectPositionTreshold:Float;
	var recycleObjectPositionTreshold:Float;
	var createObjectTimeTreshold:Float;
	var objectPositionMagnitude:Int = 3000;
	var velocityPositionMarkers:Array<Float> = [];
	var currentSvIndex:Int = 0;
	var initialPoolSizePerLane:Int = 2;

	public function new(ruleset:GameplayRuleset, song:Song, player:Int, playbackRate:Float = 1, noSliderVelocity:Bool = false)
	{
		this.ruleset = ruleset;
		this.song = song;
		this.player = player;
		this.playbackRate = playbackRate;
		this.noSliderVelocity = noSliderVelocity;
		songLength = song.length;
		config = Settings.playerConfigs[player];

		updatePoolingPositions();
		initializePositionMarkers();
		updateCurrentTrackPosition();
		initializeInfoPools();
		initializeObjectPool();
	}

	public function update()
	{
		updateAndScoreActiveObjects();
		updateAndScoreHeldObjects();
		updateDeadObjects();
	}

	public function draw()
	{
		var groups = [activeNoteLanes, deadNoteLanes, heldLongNoteLanes];
		for (lanes in groups)
		{
			for (lane in lanes)
			{
				for (note in lane)
					note.draw();
			}
		}
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
		if (noSliderVelocity)
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
		if (noSliderVelocity)
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
		if (noSliderVelocity)
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
		activeNoteLanes[info.playerLane].push(new Note(info, this, ruleset.playfields[player]));
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

	function updateAndScoreActiveObjects()
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
				note.update(FlxG.elapsed);
			}
		}
	}

	function scoreActiveObjects()
	{
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

	function updateAndScoreHeldObjects()
	{
		scoreHeldObjects();

		for (lane in heldLongNoteLanes)
		{
			for (note in lane)
			{
				note.updateSpritePositions(currentTrackPosition, currentVisualPosition);
				note.update(FlxG.elapsed);
			}
		}
	}

	function scoreHeldObjects()
	{
		var window = ruleset.scoreProcessors[player].judgementWindow[Judgement.SHIT] * ruleset.scoreProcessors[player].windowReleaseMultiplier[Judgement.SHIT];

		for (lane in heldLongNoteLanes)
		{
			while (lane.length > 0 && !lane[0].currentlyBeingHeld && currentAudioPosition > lane[0].info.endTime + window)
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

	function updateDeadObjects()
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
				note.update(FlxG.elapsed);
			}
		}
	}

	function get_scrollSpeed()
	{
		return config.scrollSpeed / playbackRate;
	}
}
