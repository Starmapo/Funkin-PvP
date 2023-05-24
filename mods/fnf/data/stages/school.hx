var bgGirls:FlxSprite;
var danceDir:Bool = false;
var daPixelZoom:Float = 6;

function onCreate()
{
	state.defaultCamZoom = 0.9;

	var bgSky = new FlxSprite().loadGraphic(Paths.getImage('stages/weeb/weebSky'));
	bgSky.scrollFactor.set(0.1, 0.1);
	bgSky.active = false;
	addBehindChars(bgSky);

	var repositionShit = -200;

	var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.getImage('stages/weeb/weebSchool'));
	bgSchool.scrollFactor.set(0.6, 0.90);
	bgSchool.active = false;
	addBehindChars(bgSchool);

	var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.getImage('stages/weeb/weebStreet'));
	bgStreet.scrollFactor.set(0.95, 0.95);
	bgStreet.active = false;
	addBehindChars(bgStreet);

	var widShit = Std.int(bgSky.width * 6);
	if (!Settings.lowQuality)
	{
		var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.getImage('stages/weeb/weebTreesBack'));
		fgTrees.scrollFactor.set(0.9, 0.9);
		fgTrees.active = false;
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		fgTrees.updateHitbox();
		addBehindChars(fgTrees);
	}

	var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
	var treetex = Paths.getSpritesheet('stages/weeb/weebTrees');
	bgTrees.frames = treetex;
	bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
	bgTrees.animation.play('treeLoop');
	bgTrees.scrollFactor.set(0.85, 0.85);
	addBehindChars(bgTrees);

	if (!Settings.lowQuality)
	{
		var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
		treeLeaves.frames = Paths.getSpritesheet('stages/weeb/petals');
		treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
		treeLeaves.animation.play('leaves');
		treeLeaves.scrollFactor.set(0.85, 0.85);
		treeLeaves.setGraphicSize(widShit);
		treeLeaves.updateHitbox();
		addBehindChars(treeLeaves);
	}

	bgSky.setGraphicSize(widShit);
	bgSchool.setGraphicSize(widShit);
	bgStreet.setGraphicSize(widShit);
	bgTrees.setGraphicSize(Std.int(widShit * 1.4));

	bgSky.updateHitbox();
	bgSchool.updateHitbox();
	bgStreet.updateHitbox();
	bgTrees.updateHitbox();

	if (!Settings.lowQuality && Settings.distractions)
	{
		bgGirls = new FlxSprite(-100, 190);
		bgGirls.frames = Paths.getSpritesheet('stages/weeb/bgFreaks');
		bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
		bgGirls.animation.play('danceLeft');
		bgGirls.animation.finish();
		bgGirls.scrollFactor.set(0.9, 0.9);

		if (songName == 'Roses')
		{
			bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
			bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
			bgGirlsDance();
			bgGirls.animation.finish();
		}
		
		bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		bgGirls.updateHitbox();
		addBehindChars(bgGirls);
	}
	
	bf.charPosX += 200;
	
	if (Settings.lowQuality || !Settings.distractions)
		close();
}

function onBeatHit(beat, decBeat)
{
	bgGirlsDance();
}

function bgGirlsDance()
{
	if (bgGirls != null)
	{
		danceDir = !danceDir;

		if (danceDir)
			bgGirls.animation.play('danceRight', true);
		else
			bgGirls.animation.play('danceLeft', true);
	}
}