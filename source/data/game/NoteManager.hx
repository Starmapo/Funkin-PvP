package data.game;

import data.song.NoteInfo;
import data.song.Song;
import ui.game.Note;

class NoteManager
{
	public var nextNote:NoteInfo;
	public var currentAudioPosition:Float = 0;
	public var currentVisualPosition:Float = 0;
	public var currentTrackPosition:Float = 0;
	public var config:PlayerConfig;
	public var scrollSpeed(get, never):Float;

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
	var noteQueueLanes:Array<Array<NoteInfo>> = [];
	var activeNoteLanes:Array<Array<Note>> = [];
	var deadNoteLanes:Array<Array<Note>> = [];
	var heldLongNoteLanes:Array<Array<Note>> = [];
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

	public function getPositionFromTime(time:Float)
	{
		var i = 0;
		while (i < song.scrollVelocities.length)
		{
			if (time < song.scrollVelocities[i].startTime)
				break;
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
				continue;

			if (forward == (multiplier > 0))
				continue;

			forward = multiplier > 0;
			changes.push({
				startTime: song.scrollVelocities[i].startTime,
				position: velocityPositionMarkers[i]
			});

			i++;
		}

		return changes;
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

	function updateCurrentTrackPosition()
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

	function createPoolObject(info:NoteInfo)
	{
		activeNoteLanes[info.lane].push(new Note(info, this, ruleset.playfields[player]));
	}

	function get_scrollSpeed()
	{
		return config.scrollSpeed / playbackRate;
	}
}
