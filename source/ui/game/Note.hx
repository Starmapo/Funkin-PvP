package ui.game;

import data.PlayerConfig;
import data.game.NoteManager;
import data.game.SVDirectionChange;
import data.skin.NoteSkin;
import data.song.NoteInfo;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import sprites.AnimatedSprite;
import sprites.game.Character;

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
	public var animSuffix:String;
	public var heyNote:Bool;
	public var gfSing:Bool;
	public var noAnim:Bool;
	public var noMissAnim:Bool;
	public var character:Character;
	public var texture(default, set):String;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	var manager:NoteManager;
	var playfield:Playfield;
	var noteSkin:NoteSkin;
	var config:PlayerConfig;
	var bodyOffset:Float;
	var svDirectionChanges:Array<SVDirectionChange>;
	var currentBodySize:Int;
	var longNoteSizeDifference:Float;
	var toUpdate:Array<FlxSprite>;

	public function new(info:NoteInfo, ?manager:NoteManager, ?playfield:Playfield, ?noteSkin:NoteSkin)
	{
		super();
		this.playfield = playfield;
		this.manager = manager;
		this.noteSkin = noteSkin;
		if (manager != null)
			config = manager.config;

		initializeSprites();
		initializeObject(info);

		scrollFactor.set();
	}

	public function initializeObject(info:NoteInfo)
	{
		this.info = info;

		texture = '';

		tint = FlxColor.WHITE;

		head.visible = true;
		if (manager != null)
			initialTrackPosition = manager.getPositionFromTime(info.startTime);
		else
			initialTrackPosition = info.startTime;
		currentlyBeingHeld = false;
		toUpdate.resize(1);

		if (!info.isLongNote)
		{
			tail.visible = body.visible = false;
			latestTrackPosition = initialTrackPosition;
		}
		else
		{
			if (manager != null)
			{
				svDirectionChanges = manager.getSVDirectionChanges(info.startTime, info.endTime);
				endTrackPosition = manager.getPositionFromTime(info.endTime);
			}
			else
			{
				svDirectionChanges = [];
				endTrackPosition = info.endTime;
			}
			tail.visible = body.visible = true;
			updateLongNoteSize(initialTrackPosition, info.startTime);

			if (config != null)
			{
				var flipY = config.downScroll;
				if (manager != null && manager.isSVNegative(info.endTime))
					flipY = !flipY;
				tail.flipY = flipY;
			}
			else
				tail.flipY = false;

			toUpdate.push(body);
			toUpdate.push(tail);
		}

		animSuffix = (info.type == 'Alt Animation' ? '-alt' : '');
		heyNote = (info.type == 'Hey!');
		gfSing = (info.type == 'GF Sing');
		noAnim = (info.type == 'No Animation');
		noMissAnim = (info.type == 'No Animation');
		character = null;

		updateWithCurrentPositions();
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

		var speed = manager != null ? manager.scrollSpeed : 1;
		currentBodySize = Math.round((latestTrackPosition - earliestTrackPosition) * speed - longNoteSizeDifference);
	}

	public function updateSpritePositions(offset:Float, curTime:Float)
	{
		if (playfield != null)
			x = playfield.receptors.members[info.playerLane].x + offsetX;

		var hitPosition = playfield != null ? playfield.receptors.members[info.playerLane].y : 50;
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

		y = spritePosition + offsetY;

		if (!info.isLongNote)
			return;

		body.setGraphicSize(body.width, currentBodySize);
		body.updateHitbox();

		var earliestSpritePosition = hitPosition + getSpritePosition(offset, earliestTrackPosition);
		if (config != null && config.downScroll)
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

	public function reloadTexture()
	{
		var tex = texture;
		if (tex.length < 1)
			tex = noteSkin.notesImage;
		if (!Paths.existsPath('images/$tex.png', noteSkin.mod))
			tex = 'notes/default';

		if (Paths.isSpritesheet(tex, noteSkin.mod))
		{
			var frames = Paths.getSpritesheet(tex, noteSkin.mod);
			for (spr in [head, body, tail])
				spr.frames = frames;
		}
		else
		{
			var image = Paths.getImage(tex, noteSkin.mod);
			head.loadGraphic(image, true, Math.round(image.width / 4), Math.round(image.height / 5));

			var holdImage = Paths.getImage(tex + '-ends', noteSkin.mod);
			for (spr in [body, tail])
				spr.loadGraphic(holdImage, true, Math.round(holdImage.width / 4), Math.round(holdImage.height / 2));
		}
		var data = noteSkin.notes[info.playerLane];

		var notesScale = config != null ? config.notesScale : 1;
		var scale = noteSkin.notesScale * notesScale;
		head.scale.set(scale, scale);
		head.offsetScale.set(notesScale, notesScale);
		head.addAnim({
			name: 'head',
			atlasName: data.headAnim,
			indices: data.headIndices,
			fps: 0,
			loop: false
		}, true);
		bodyOffset = head.height / 2;
		longNoteSizeDifference = head.height / 2;

		body.scale.copyFrom(head.scale);
		body.offsetScale.copyFrom(head.offsetScale);
		body.addAnim({
			name: 'body',
			atlasName: data.bodyAnim,
			indices: data.bodyIndices,
			fps: 0,
			loop: false
		}, true);
		body.x = x + (head.width / 2) - (body.width / 2);

		tail.scale.copyFrom(head.scale);
		tail.offsetScale.copyFrom(head.offsetScale);
		tail.addAnim({
			name: 'tail',
			atlasName: data.tailAnim,
			indices: data.tailIndices,
			fps: 0,
			loop: false
		}, true);
		tail.x = x + (head.width / 2) - (tail.width / 2);

		updateWithCurrentPositions();
	}

	public function updateWithCurrentPositions()
	{
		if (manager != null)
			updateSpritePositions(manager.currentTrackPosition, manager.currentVisualPosition);
		else
			updateSpritePositions(0, 0);
	}

	override function update(elapsed:Float)
	{
		for (spr in toUpdate)
		{
			if (spr != null && spr.exists && spr.active)
				spr.update(elapsed);
		}
	}

	override function destroy()
	{
		super.destroy();
		info = null;
		head = null;
		body = null;
		tail = null;
		manager = null;
		playfield = null;
		noteSkin = null;
		config = null;
		svDirectionChanges = null;
		toUpdate = null;
	}

	function initializeSprites()
	{
		head = new AnimatedSprite();
		head.antialiasing = noteSkin.antialiasing;

		body = new AnimatedSprite();
		body.alpha = config != null && config.transparentHolds ? 0.6 : 1;

		tail = new AnimatedSprite();
		tail.antialiasing = noteSkin.antialiasing;
		tail.alpha = body.alpha;

		add(body);
		add(tail);
		add(head);

		toUpdate = [head];
	}

	function getSpritePosition(offset:Float, initialPos:Float)
	{
		var downScroll = config != null ? config.downScroll : false;
		var speed = manager != null ? manager.scrollSpeed : 1;
		return ((initialPos - offset) * (downScroll ? -speed : speed));
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

	function set_texture(value:String)
	{
		if (value != null && texture != value)
		{
			texture = value;
			reloadTexture();
		}
		return value;
	}
}
