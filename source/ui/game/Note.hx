package ui.game;

import data.PlayerConfig;
import data.game.NoteManager;
import data.game.SVDirectionChange;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;

class Note extends FlxSpriteGroup
{
	public var currentlyBeingHeld:Bool = false;
	public var info:NoteInfo;
	public var tint:FlxColor;
	public var hitPosition:Float;
	public var holdEndHitPosition:Float;
	public var initialTrackPosition:Float;
	public var endTrackPosition:Float;
	public var earliestTrackPosition:Float;
	public var latestTrackPosition:Float;

	var manager:NoteManager;
	var playfield:Playfield;
	var head:AnimatedSprite;
	var body:AnimatedSprite;
	var tail:AnimatedSprite;
	var noteSkin:NoteSkin;
	var config:PlayerConfig;
	var bodyOffset:Float;
	var svDirectionChanges:Array<SVDirectionChange>;
	var currentBodySize:Int;
	var longNoteSizeDifference:Float;

	public function new(info:NoteInfo, manager:NoteManager, playfield:Playfield)
	{
		super();
		this.playfield = playfield;
		this.manager = manager;
		noteSkin = playfield.noteSkin;
		config = manager.config;

		initializeSprites(info);
		initializeObject(info);
	}

	public function initializeObject(info:NoteInfo)
	{
		this.info = info;
		hitPosition = playfield.receptors.members[info.playerLane].y;

		tint = FlxColor.WHITE;

		head.visible = true;
		head.color = tint;
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
			tail.color = body.color = tint;
			endTrackPosition = manager.getPositionFromTime(info.endTime);
			updateLongNoteSize(initialTrackPosition, info.startTime);

			var flipY = config.downScroll;
			if (manager.isSVNegative(info.endTime))
				flipY = !flipY;
			tail.flipY = flipY;
		}

		updateSpritePositions(manager.currentTrackPosition, manager.currentVisualPosition);
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
		currentBodySize = Std.int((latestTrackPosition - earliestTrackPosition) * manager.scrollSpeed - longNoteSizeDifference);
	}

	public function updateSpritePositions(offset:Float, curTime:Float)
	{
		var spritePosition;
		if (currentlyBeingHeld)
		{
			updateLongNoteSize(offset, curTime);
			if (curTime > info.startTime)
				spritePosition = hitPosition;
			else
				spritePosition = getSpritePosition(offset, initialTrackPosition);
		}
		else
			spritePosition = getSpritePosition(offset, initialTrackPosition);

		head.y = spritePosition;

		if (!info.isLongNote)
			return;

		body.setGraphicSize(Std.int(body.width), currentBodySize);
		var earliestSpritePosition = getSpritePosition(offset, earliestTrackPosition);
		if (config.downScroll)
		{
			body.y = earliestSpritePosition + bodyOffset - body.height;
			tail.y = body.y - tail.height;
		}
		else
		{
			body.y = earliestSpritePosition + bodyOffset;
			tail.y = body.y + body.height;
		}

		if (currentBodySize + longNoteSizeDifference <= head.height / 2
			|| currentBodySize <= 0
			|| curTime >= info.endTime
			&& currentlyBeingHeld)
			tail.visible = body.visible = false;
	}

	public function killNote()
	{
		tint = FlxColor.fromRGB(200, 200, 200);
		head.color = tint;
		if (info.isLongNote)
			tail.color = body.color = tint;
	}

	function initializeSprites(info:NoteInfo)
	{
		var frames = Paths.getSpritesheet(noteSkin.notesImage);

		head = new AnimatedSprite();
		head.frames = frames;
		head.addAnim({
			name: 'head',
			atlasName: noteSkin.notes[info.playerLane].headAnim,
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
			atlasName: noteSkin.notes[info.playerLane].bodyAnim,
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
			atlasName: noteSkin.notes[info.playerLane].tailAnim,
			fps: 0,
			loop: false
		}, true);
		tail.antialiasing = noteSkin.antialiasing;
		tail.scale.copyFrom(head.scale);
		tail.updateHitbox();
		add(tail);
	}

	function getSpritePosition(offset:Float, initialPos:Float)
	{
		return hitPosition + ((initialPos - offset) * (config.downScroll ? -manager.scrollSpeed : manager.scrollSpeed));
	}
}
