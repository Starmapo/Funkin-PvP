import("flixel.system.FlxBGSprite");

var brightShader:FlxRuntimeShader;
var defaultBrightVal:Float = -0.04;
var brightSpeed:Float = 0.1;
var brightMagnitude:Float = 0.04;
var grayscaleShader:FlxRuntimeShader;
var combat:Bool = false;
var battle:FlxSprite;
var battleBG:FlxSprite;
var doBattle:Bool = false;
var ogOpponent:String;
var ogBF:String;

function onCreatePost()
{
	doBattle = (opponent.info.name == "sans" || opponent.info.name == "sansScared" || opponent.info.name == "sansTired") && opponent.info.mod == modID && (bf.info.name == "bfSans" || bf.info.name == "bfsanswaterfall" || bf.info.name == "bfchara") && bf.info.mod == modID;
	ogOpponent = opponent.info.name;
	ogBF = bf.info.name;
	
	if (doBattle)
	{
		battle = new FlxSprite(-600, -200).loadGraphic(Paths.getImage('stages/battleUI/battle'));
		battle.antialiasing = true;
		battle.alpha = 0.0001;

		battleBG = new FlxSprite(-600, 0).loadGraphic(Paths.getImage('stages/battleUI/bg'));
		battleBG.alpha = 0.0001;
		battleBG.setGraphicSize(Std.int(battle.width));
		battleBG.updateHitbox();

		addBehindChars(battle);
		addBehindChars(battleBG);
		
		precacheCharacter("sansbattle");
		if (bf.info.name == "bfchara")
			precacheCharacter("charabattle");
		else
			precacheCharacter("bfbattle");
	}
	
	Paths.getSound("sans/countdown");
	
	if (Settings.shaders)
	{
		brightShader = getShader("bright");
		brightShader.setFloat("contrast", 1);
		FlxG.camera.addShader(brightShader);
		
		if (!doBattle)
		{
			grayscaleShader = getShader("grayscale");
			grayscaleShader.setFloat("influence", 1);
		}
	}
	
	if (opponent.info.name == "sansScared" && opponent.info.mod == modID)
		precacheCharacter("sansTired");
}

function onUpdatePost(elapsed)
{
	var bpmScale = (timing.curTimingPoint != null ? (timing.curTimingPoint.bpm / 60) : 1);
	
	if (combat && doBattle)
		bf.y = 1248.7 + Math.sin((timing.audioPosition / 1000) * bpmScale * 2.5) * 20;
		
	if (Settings.shaders && brightSpeed != 0)
		setBrightness(defaultBrightVal + Math.sin((timing.audioPosition / 1000) * bpmScale * brightSpeed) * brightMagnitude);
	else
		setBrightness(defaultBrightVal);
}

function onEvent(event, params)
{
	switch (event)
	{
		case "Play Animation":
			if (params[0] == "indiecross_snap" && opponent.animation.exists(params[0]))
				opponent.danceDisabled = true;
		case "Switch to Combat":
			combat = !combat;
			FlxG.camera.visible = true;
			state.camBop = bg.visible = !combat;
			if (staticBG != null)
				staticBG.visible = !combat;
			if (doBattle)
			{
				battle.alpha = battleBG.alpha = combat ? 1 : 0;
				if (combat)
				{
					opponent.changeCharacter("sansbattle");
					opponent.setCharacterPosition(155.1, 436.5);
					opponent.danceDisabled = false;
					switch (bf.info.name)
					{
						case "bfchara":
							bf.changeCharacter("charabattle");
						default:
							bf.changeCharacter("bfbattle");
					}
					bf.setCharacterPosition(158.3, 1248.7);
					FlxG.camera.zoom = state.defaultCamZoom = 0.35;
				}
				else
				{
					opponent.changeCharacter(ogOpponent);
					opponent.setCharacterPosition(-300, 25);
					bf.changeCharacter(ogBF);
					bf.setCharacterPosition(616.3, 25);
					FlxG.camera.zoom = state.defaultCamZoom = 0.9;
				}
				state.updateCamPosition();
				FlxG.camera.snapToTarget();
			}
			else
			{
				if (grayscaleShader != null)
				{
					if (combat)
						FlxG.camera.addShader(grayscaleShader);
					else
						FlxG.camera.removeShader(grayscaleShader);
				}
			}
		case "Set Camera Visible":
			FlxG.camera.visible = params[0] == "1";
		case "Sans Tired":
			if (opponent.info.name == "sansScared" && opponent.info.mod == modID)
				opponent.changeCharacter("sansTired");
	}
}

function setBrightness(value)
{
	if (brightShader != null)
		brightShader.setFloat("brightness", value);
}