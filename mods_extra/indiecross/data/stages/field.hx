var shader:FlxRuntimeShader;
var fgStatic:FlxSprite;
var fgGrain:FlxSprite;

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
	}
	else
		close();
}

function onDeath(player)
{
	FlxTween.tween(fgStatic, {alpha: 0}, 1);
	FlxTween.tween(fgGrain, {alpha: 0}, 1);
}

function setChroma(value)
{
	shader.setFloat("rOffset", value);
	shader.setFloat("bOffset", -value);
}