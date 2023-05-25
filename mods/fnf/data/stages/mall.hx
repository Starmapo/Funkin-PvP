var upperBoppers:FlxSprite;
var bottomBoppers:FlxSprite;
var santa:FlxSprite;

function onCreate()
{
	state.defaultCamZoom = 0.8;

	var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.getImage('stages/christmas/bgWalls'));
	bg.antialiasing = true;
	bg.scrollFactor.set(0.2, 0.2);
	bg.active = false;
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	addBehindChars(bg);

	if (!Settings.lowQuality)
	{
		if (Settings.distractions)
		{
			upperBoppers = new FlxSprite(-240, -90);
			upperBoppers.frames = Paths.getSpritesheet('stages/christmas/upperBop');
			upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
			upperBoppers.antialiasing = true;
			upperBoppers.scrollFactor.set(0.33, 0.33);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			addBehindChars(upperBoppers);
		}

		var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.getImage('stages/christmas/bgEscalator'));
		bgEscalator.antialiasing = true;
		bgEscalator.scrollFactor.set(0.3, 0.3);
		bgEscalator.active = false;
		bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		bgEscalator.updateHitbox();
		addBehindChars(bgEscalator);
	}

	var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.getImage('stages/christmas/christmasTree'));
	tree.antialiasing = true;
	tree.scrollFactor.set(0.40, 0.40);
	tree.active = false;
	addBehindChars(tree);

	if (Settings.distractions)
	{
		bottomBoppers = new FlxSprite(-300, 140);
		bottomBoppers.frames = Paths.getSpritesheet('stages/christmas/bottomBop');
		bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
		bottomBoppers.antialiasing = true;
		bottomBoppers.scrollFactor.set(0.9, 0.9);
		bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
		bottomBoppers.updateHitbox();
		addBehindChars(bottomBoppers);
	}

	var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.getImage('stages/christmas/fgSnow'));
	fgSnow.active = false;
	fgSnow.antialiasing = true;
	addBehindChars(fgSnow);

	if (Settings.distractions)
	{
		santa = new FlxSprite(-840, 150);
		santa.frames = Paths.getSpritesheet('stages/christmas/santa');
		santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		santa.antialiasing = true;
		addBehindChars(santa);
	}

	bf.charPosX += 200;

	if (!Settings.distractions)
		close();
}

function onBeatHit(beat, decBeat)
{
	if (upperBoppers != null)
		upperBoppers.animation.play('bop', true);
	if (bottomBoppers != null)
		bottomBoppers.animation.play('bop', true);
	if (santa != null)
		santa.animation.play('idle', true);
}
