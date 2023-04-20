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
	public var tint(default, set):FlxColor;
	public var initialTrackPosition:Float;
	public var endTrackPosition:Float;
	public var earliestTrackPosition:Float;
	public var latestTrackPosition:Float;
	public var head:AnimatedSprite;
	public var body:AnimatedSprite;
	public var tail:AnimatedSprite;

	var manager:NoteManager;
	var playfield:Playfield;
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

		tint = FlxColor.WHITE;

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
		x = playfield.receptors.members[info.playerLane].x;

		var hitPosition = playfield.receptors.members[info.playerLane].y;
		var spritePosition;
		if (currentlyBeingHeld)
		{
			updateLongNoteSize(offset, curTime);
			if (curTime > info.startTime)
				spritePosition = hitPosition;
			else
				spritePosition = hitPosition + getSpritePosition(offset, initialTrackPosition);
		}
		else
			spritePosition = hitPosition + getSpritePosition(offset, initialTrackPosition);

		y = spritePosition;

		if (!info.isLongNote)
			return;

		body.setGraphicSize(Std.int(body.width), currentBodySize);
		body.updateHitbox();

		var earliestSpritePosition = hitPosition + getSpritePosition(offset, earliestTrackPosition);
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
			|| (curTime >= info.endTime && currentlyBeingHeld))
			tail.visible = body.visible = false;
	}

	public function killNote()
	{
		tint = FlxColor.fromRGBFloat(0.3, 0.3, 0.3);
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
		body.x = (head.width / 2) - (body.width / 2);

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
		tail.x = (head.width / 2) - (tail.width / 2);

		add(body);
		add(tail);
		add(head);
	}

	function getSpritePosition(offset:Float, initialPos:Float)
	{
		return ((initialPos - offset) * (config.downScroll ? -manager.scrollSpeed : manager.scrollSpeed));
	}

	function set_tint(value:FlxColor)
	{
		if (tint != value)
		{
			tint = value;
			tail.color = body.color = head.color = tint;
		}
		return value;
	}
}
