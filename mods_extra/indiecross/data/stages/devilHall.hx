var shader:FlxRuntimeShader;
var fgStatic:FlxSprite;
var fgGrain:FlxSprite;
var devilIntroSpr:FlxSprite;

function onCreatePost()
{
	if (Settings.shaders)
	{
		shader = getShader("chromaticAberration");
		setChroma(0.001);
		addGameShader(shader);
	}
	
	if (!Settings.lowQuality)
	{
		fgStatic = new FlxSprite();
		fgStatic.frames = Paths.getSpritesheet('stages/CUpheqdshid');
		fgStatic.animation.addByPrefix('play', 'Cupheadshit_gif instance 1', 24, true);
		fgStatic.animation.play('play', true);
		fgStatic.setGraphicSize(FlxG.width);
		fgStatic.updateHitbox();
		fgStatic.screenCenter();
		fgStatic.antialiasing = true;
		fgStatic.scrollFactor.set();
		fgStatic.cameras = [camOther];
		add(fgStatic);
		
		fgGrain = new FlxSprite();
		fgGrain.frames = Paths.getSpritesheet('stages/Grainshit');
		fgGrain.animation.addByPrefix('play', 'Geain instance 1', 24, true);
		fgGrain.animation.play('play', true);
		fgGrain.setGraphicSize(FlxG.width);
		fgGrain.updateHitbox();
		fgGrain.screenCenter();
		fgGrain.antialiasing = true;
		fgGrain.scrollFactor.set();
		fgGrain.cameras = [camOther];
		add(fgGrain);
		
		if (opponent.info.name == "devilFull" && opponent.info.mod == modID)
		{
			devilIntroSpr = new FlxSprite(-500, -335);
			devilIntroSpr.frames = Paths.getSpritesheet('stages/devilHall/Devil_Intro');
			devilIntroSpr.animation.addByPrefix('start', "Intro instance 1", 24, false);
			devilIntroSpr.updateHitbox();
			devilIntroSpr.antialiasing = true;
			devilIntroSpr.setGraphicSize(Std.int(devilIntroSpr.width * 1.3));
			add(devilIntroSpr);
			devilIntroSpr.alpha = 0.00001;
		}
	}
	else
		close();
}

function onStartSong()
{
	if (devilIntroSpr == null)
		return;
	
	devilIntroSpr.alpha = 1.0;
	opponent.alpha = 0.0001;
	devilIntroSpr.animation.play('start', true);

	devilIntroSpr.animation.finishCallback = function(name:String)
	{
		FlxG.bitmap.remove(devilIntroSpr.graphic);
		devilIntroSpr.destroy();
		remove(devilIntroSpr);
		opponent.alpha = 1;
	}
}

function onDeath(player)
{
	if (Settings.lowQuality)
		return;
		
	FlxTween.tween(fgStatic, {alpha: 0}, 1);
	FlxTween.tween(fgGrain, {alpha: 0}, 1);
}

function setChroma(value)
{
	shader.setFloat("rOffset", value);
	shader.setFloat("bOffset", -value);
}