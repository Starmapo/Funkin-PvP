package states.editors;

import data.char.CharacterInfo;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import sprites.game.Character;

class CharacterEditorState extends FNFState
{
	var charName:String;
	var charInfo:CharacterInfo;
	var char:Character;
	var positionIndicator:FlxSprite;
	var camPos:FlxObject;

	public function new(?charName:String)
	{
		super();
		if (charName == null)
			charName = 'bf';
		this.charName = charName;

		persistentUpdate = true;
	}

	override function create()
	{
		charInfo = new CharacterInfo({
			anims: [
				{
					name: 'hey',
					atlasName: 'BF HEY!!'
				},
				{
					name: 'idle',
					atlasName: 'BF idle dance'
				},
				{
					name: 'scared',
					atlasName: 'BF idle shaking'
				},
				{
					name: 'singDOWN',
					atlasName: 'BF NOTE DOWN'
				},
				{
					name: 'singDOWN-miss',
					atlasName: 'BF NOTE DOWN MISS'
				},
				{
					name: 'singLEFT',
					atlasName: 'BF NOTE LEFT'
				},
				{
					name: 'singLEFT-miss',
					atlasName: 'BF NOTE LEFT MISS'
				},
				{
					name: 'singRIGHT',
					atlasName: 'BF NOTE RIGHT'
				},
				{
					name: 'singRIGHT-miss',
					atlasName: 'BF NOTE RIGHT MISS'
				},
				{
					name: 'singUP',
					atlasName: 'BF NOTE UP'
				},
				{
					name: 'singUP-miss',
					atlasName: 'BF NOTE UP MISS'
				}
			]
		});

		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF222222;
		bg.scrollFactor.set();
		add(bg);

		char = new Character(0, 0, charInfo);
		add(char);

		positionIndicator = new FlxSprite().makeGraphic(10, 2, FlxColor.BLACK);
		positionIndicator.offset.set(5);
		add(positionIndicator);
		updatePositionIndicator();

		camPos = new FlxObject();
		add(camPos);
		FlxG.camera.follow(camPos);
		FlxG.camera.snapToTarget();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.anyPressed([I, J, K, L]))
		{
			var angle = FlxG.keys.angleFromKeys([I, J, K, L]);
			camPos.velocity.setPolarDegrees(900, angle);
		}
		else
			camPos.velocity.set();
		camPos.update(elapsed);

		char.update(elapsed);
	}

	function updatePositionIndicator()
	{
		positionIndicator.setPosition(char.x + (char.width / 2) + charInfo.positionOffset[0], char.y + char.height + charInfo.positionOffset[1]);
	}

	function resetCamPos()
	{
		camPos.setPosition(char.x + (char.width / 2) + charInfo.cameraOffset[0], char.y + (char.height / 2) + charInfo.cameraOffset[1]);
	}
}
