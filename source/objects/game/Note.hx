package objects.game;

import backend.game.NoteManager;
import backend.game.SVDirectionChange;
import backend.settings.PlayerConfig;
import backend.structures.skin.NoteSkin;
import backend.structures.song.NoteInfo;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import objects.game.Character;

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
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var needsReload:Bool = true;
	
	var manager:NoteManager;
	var playfield:Playfield;
	var skin:NoteSkin;
	var config:PlayerConfig;
	var bodyOffset:Float;
	var svDirectionChanges:Array<SVDirectionChange>;
	var currentBodySize:Int;
	var longNoteSizeDifference:Float;
	var toUpdate:Array<FlxSprite>;
	// private because it's not well implemented yet
	var texture(default, set):String;
	
	public function new(info:NoteInfo, ?manager:NoteManager, ?playfield:Playfield, ?skin:NoteSkin)
	{
		super();
		this.playfield = playfield;
		this.manager = manager;
		if (skin == null)
			skin = NoteSkin.loadSkinFromName('fnf:default');
		this.skin = skin;
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
		initialTrackPosition = manager != null ? manager.getPositionFromTime(info.startTime) : info.startTime;
		currentlyBeingHeld = false;
		toUpdate.resize(1);
		
		if (!info.isLongNote)
		{
			tail.visible = body.visible = false;
			latestTrackPosition = initialTrackPosition;
		}
		else
		{
			svDirectionChanges = manager != null ? manager.getSVDirectionChanges(info.startTime, info.endTime) : [];
			endTrackPosition = manager != null ? manager.getPositionFromTime(info.endTime) : info.endTime;
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
		var startPosition = curTime >= info.startTime ? offset : initialTrackPosition;
		
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
		
		currentBodySize = Math.round((latestTrackPosition - earliestTrackPosition) * (manager != null ? manager.scrollSpeed : 1.0) - longNoteSizeDifference);
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
		var tex = skin.image;
		var mod = skin.mod;
		if (!Paths.existsPath('images/$tex.png', mod))
		{
			tex = 'notes/default';
			mod = 'fnf';
		}
		
		if (Paths.isSpritesheet(tex, mod))
		{
			var frames = Paths.getSpritesheet(tex, mod);
			for (spr in [head, body, tail])
				spr.frames = frames;
		}
		else
		{
			var image = Paths.getImage(tex, mod);
			head.loadGraphic(image, true, skin.tileWidth, skin.tileHeight);
			
			var holdSpr = [body, tail];
			var holdImage = Paths.getImage(tex + '-ends', mod);
			if (holdImage != null)
			{
				for (spr in holdSpr)
					spr.loadGraphic(holdImage, true, Math.round(holdImage.width / 4), Math.round(holdImage.height / 2));
			}
			else
			{
				for (spr in holdSpr)
					spr.loadGraphic(image, true, skin.tileWidth, skin.tileHeight);
			}
		}
		var data = skin.notes[info.playerLane];
		
		var notesScale = config != null ? config.notesScale : 1;
		var scale = skin.notesScale * notesScale;
		head.scale.set(scale, scale);
		head.frameOffsetScale = skin.notesScale;
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
		body.frameOffsetScale = head.frameOffsetScale;
		body.addAnim({
			name: 'body',
			atlasName: data.bodyAnim,
			indices: data.bodyIndices,
			fps: 0,
			loop: false
		}, true);
		body.x = x + (head.width / 2) - (body.width / 2);
		
		tail.scale.copyFrom(head.scale);
		tail.frameOffsetScale = head.frameOffsetScale;
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
		updateSpritePositions(manager != null ? manager.currentTrackPosition : 0, manager != null ? manager.currentVisualPosition : 0);
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
		head = FlxDestroyUtil.destroy(head);
		body = FlxDestroyUtil.destroy(body);
		tail = FlxDestroyUtil.destroy(tail);
		manager = null;
		playfield = null;
		skin = null;
		config = null;
		svDirectionChanges = null;
		toUpdate = null;
	}
	
	function initializeSprites()
	{
		head = new AnimatedSprite();
		head.antialiasing = skin.antialiasing;
		
		body = new AnimatedSprite();
		body.alpha = config != null && config.transparentHolds ? 0.6 : 1;
		
		tail = new AnimatedSprite();
		tail.antialiasing = skin.antialiasing;
		tail.alpha = body.alpha;
		
		add(body);
		add(tail);
		add(head);
		
		toUpdate = [head];
	}
	
	function getSpritePosition(offset:Float, initialPos:Float)
	{
		var downScroll = config != null ? config.downScroll : false;
		var speed = manager != null ? manager.scrollSpeed : 1.0;
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
