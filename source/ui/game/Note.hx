package ui.game;

import data.game.NoteManager;
import data.game.SVDirectionChange;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import flixel.group.FlxSpriteGroup;
import sprites.AnimatedSprite;

class Note extends FlxSpriteGroup
{
	public var currentlyBeingHeld:Bool = false;

	var info:NoteInfo;
	var manager:NoteManager;
	var playfield:Playfield;
	var head:AnimatedSprite;
	var body:AnimatedSprite;
	var tail:AnimatedSprite;
	var hitPosition:Float;
	var holdEndHitPosition:Float;
	var initialTrackPosition:Float;
	var noteSkin:NoteSkin;
	var bodyOffset:Float;
	var endTrackPosition:Float;
	var earliestTrackPosition:Float;
	var latestTrackPosition:Float;
	var svDirectionChanges:Array<SVDirectionChange>;
	var currentBodySize:Float;
	var longNoteSizeDifference:Float;

	public function new(info:NoteInfo, manager:NoteManager, playfield:Playfield)
	{
		super();
		this.playfield = playfield;
		this.manager = manager;
		noteSkin = playfield.noteSkin;

		initializeSprites(info);
		initializeObject(info);
	}

	public function initializeObject(info:NoteInfo)
	{
		this.info = info;
		hitPosition = playfield.receptors.members[info.lane].y;

		head.visible = true;
		initialTrackPosition = manager.getPositionFromTime(info.startTime);
		currentlyBeingHeld = false;

		if (!info.isLongNote)
		{
			tail.visible = body.visible = false;
			latestTrackPosition = initialTrackPosition;
		}
		else
		{
			svDirectionChanges = manager.getSVDirectionChanges(info.startTime, info.endTime);
			tail.visible = body.visible = true;
			endTrackPosition = manager.getPositionFromTime(info.endTime);
			updateLongNoteSize(initialTrackPosition, info.startTime);
		}
	}

	public function updateLongNoteSize(offset:Float, curTime:Float)
	{
		var startPosition = initialTrackPosition;
		if (curTime >= info.startTime)
			startPosition = offset;

		var earliestPosition = Math.min(startPosition, endTrackPosition);
		var latestPosition = Math.max(startPosition, endTrackPosition);

		for (change in svDirectionChanges)
		{
			if (curTime >= change.startTime)
				continue;

			earliestPosition = Math.min(earliestPosition, change.position);
			latestPosition = Math.min(latestPosition, change.position);
		}

		earliestTrackPosition = earliestPosition;
		latestTrackPosition = latestPosition;
		currentBodySize = (latestTrackPosition - earliestTrackPosition) * manager.scrollSpeed - longNoteSizeDifference;
	}

	function initializeSprites(info:NoteInfo)
	{
		var frames = Paths.getSpritesheet(noteSkin.notesImage);

		head = new AnimatedSprite();
		head.frames = frames;
		head.addAnim({
			name: 'head',
			atlasName: noteSkin.notes[info.lane].headAnim,
			fps: 0,
			loop: false
		}, true);
		head.antialiasing = noteSkin.antialiasing;
		head.scale.set(noteSkin.notesScale, noteSkin.notesScale);
		head.updateHitbox();
		bodyOffset = head.height / 2;
		longNoteSizeDifference = head.height / 2;
		add(head);

		body = new AnimatedSprite();
		body.frames = frames;
		body.addAnim({
			name: 'body',
			atlasName: noteSkin.notes[info.lane].bodyAnim,
			fps: 0,
			loop: false
		}, true);
		body.scale.copyFrom(head.scale);
		body.updateHitbox();
		add(body);

		tail = new AnimatedSprite();
		tail.frames = frames;
		tail.addAnim({
			name: 'tail',
			atlasName: noteSkin.notes[info.lane].tailAnim,
			fps: 0,
			loop: false
		}, true);
		tail.antialiasing = noteSkin.antialiasing;
		tail.scale.copyFrom(head.scale);
		tail.updateHitbox();
		add(tail);
	}
}
