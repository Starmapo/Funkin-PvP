package subStates.pvp;

import data.PlayerSettings;
import data.Settings;
import data.game.Judgement;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.pvp.RulesetState;

class JudgementPresetsSubState extends FNFSubState
{
	static final DEFAULT:String = 'Default (Quaver Peaceful)';
	
	static var presets:Array<JudgementPreset> = [
		{
			name: 'Andromeda Engine',
			marvWindow: 18,
			sickWindow: 43,
			goodWindow: 85,
			badWindow: 115,
			shitWindow: 166,
			missWindow: 180
		},
		{
			name: DEFAULT,
			marvWindow: 23,
			sickWindow: 57,
			goodWindow: 101,
			badWindow: 141,
			shitWindow: 169,
			missWindow: 218
		},
		{
			name: 'Forever Engine',
			marvWindow: 18,
			sickWindow: 45,
			goodWindow: 90,
			badWindow: 135,
			shitWindow: 158,
			missWindow: 180
		},
		{
			name: "Friday Night Funkin'",
			marvWindow: 18,
			sickWindow: 33,
			goodWindow: 125,
			badWindow: 150,
			shitWindow: 167,
			missWindow: 218
		},
		{
			name: 'Kade Engine',
			marvWindow: 18,
			sickWindow: 45,
			goodWindow: 90,
			badWindow: 135,
			shitWindow: 160,
			missWindow: 166
		},
		{
			name: 'Leather Engine',
			marvWindow: 25,
			sickWindow: 50,
			goodWindow: 70,
			badWindow: 100,
			shitWindow: 167,
			missWindow: 218
		},
		{
			name: 'Psych Engine',
			marvWindow: 18,
			sickWindow: 45,
			goodWindow: 90,
			badWindow: 135,
			shitWindow: 167,
			missWindow: 218
		},
		{
			name: 'Quaver Chill',
			marvWindow: 19,
			sickWindow: 47,
			goodWindow: 83,
			badWindow: 116,
			shitWindow: 139,
			missWindow: 180
		},
		{
			name: 'Quaver Extreme',
			marvWindow: 13,
			sickWindow: 32,
			goodWindow: 57,
			badWindow: 79,
			shitWindow: 127,
			missWindow: 164
		},
		{
			name: 'Quaver Impossible',
			marvWindow: 8,
			sickWindow: 20,
			goodWindow: 35,
			badWindow: 49,
			shitWindow: 127,
			missWindow: 164
		},
		{
			name: 'Quaver Lenient',
			marvWindow: 21,
			sickWindow: 52,
			goodWindow: 91,
			badWindow: 128,
			shitWindow: 153,
			missWindow: 198
		},
		{
			name: 'Quaver Standard',
			marvWindow: 18,
			sickWindow: 43,
			goodWindow: 76,
			badWindow: 106,
			shitWindow: 127,
			missWindow: 164
		},
		{
			name: 'Quaver Strict',
			marvWindow: 16,
			sickWindow: 39,
			goodWindow: 69,
			badWindow: 96,
			shitWindow: 127,
			missWindow: 164
		},
		{
			name: 'Quaver Tough',
			marvWindow: 14,
			sickWindow: 35,
			goodWindow: 62,
			badWindow: 87,
			shitWindow: 127,
			missWindow: 164
		}
	];
	
	var curSelected:Int = -1;
	var nameText:FlxText;
	var judgementGroup:FlxTypedGroup<FlxText>;
	var state:RulesetState;
	var waitTime:Float;
	
	public function new(state:RulesetState)
	{
		super();
		this.state = state;
		
		for (i in 0...presets.length)
		{
			if (presets[i].name == DEFAULT)
			{
				curSelected = i;
				break;
			}
		}
		if (curSelected < 0)
			curSelected = 0;
			
		createCamera();
		
		nameText = new FlxText(5, 5, FlxG.width - 10);
		nameText.setFormat('PhantomMuff 1.5', 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		nameText.scrollFactor.set();
		add(nameText);
		
		judgementGroup = new FlxTypedGroup();
		var curY:Float = 220;
		for (i in 0...6)
		{
			var judgementText = new FlxText(0, curY);
			judgementText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			judgementText.scrollFactor.set();
			judgementGroup.add(judgementText);
			
			curY += judgementText.height + 5;
		}
		add(judgementGroup);
		
		var tipText = new FlxText(0, FlxG.height - 5, 0, 'Press ACCEPT to apply this preset and exit\nPress BACK to exit');
		tipText.setFormat('PhantomMuff 1.5', 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		tipText.y -= tipText.height;
		tipText.screenCenter(X);
		tipText.scrollFactor.set();
		add(tipText);
		
		changeSelection();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (waitTime > 0)
		{
			waitTime -= elapsed;
			return;
		}
		
		if (PlayerSettings.checkAction(UI_LEFT_P))
			changeSelection(-1);
		if (PlayerSettings.checkAction(UI_RIGHT_P))
			changeSelection(1);
			
		if (PlayerSettings.checkAction(ACCEPT_P))
		{
			var preset = presets[curSelected];
			Settings.marvWindow = preset.marvWindow;
			Settings.sickWindow = preset.sickWindow;
			Settings.goodWindow = preset.goodWindow;
			Settings.badWindow = preset.badWindow;
			Settings.shitWindow = preset.shitWindow;
			Settings.missWindow = preset.missWindow;
			
			var windows = [
				'marvWindow',
				'sickWindow',
				'goodWindow',
				'badWindow',
				'shitWindow',
				'missWindow'
			];
			for (item in state.items)
			{
				if (windows.contains(item.data.name))
					item.updateValueText();
			}
			
			close();
			CoolUtil.playConfirmSound();
		}
		else if (PlayerSettings.checkAction(BACK_P))
			close();
	}
	
	override function destroy()
	{
		super.destroy();
		nameText = null;
		judgementGroup = null;
		state = null;
	}
	
	override function onOpen()
	{
		waitTime = 0.1;
		super.onOpen();
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrapInt(curSelected + change, 0, presets.length - 1);
		
		var preset = presets[curSelected];
		nameText.text = preset.name;
		
		for (i in 0...judgementGroup.length)
		{
			var window = switch (i)
			{
				case 1: preset.sickWindow;
				case 2: preset.goodWindow;
				case 3: preset.badWindow;
				case 4: preset.shitWindow;
				case 5: preset.missWindow;
				default: preset.marvWindow;
			}
			var text = judgementGroup.members[i];
			text.text = (i : Judgement).getName() + ': ' + window + 'ms';
			text.screenCenter(X);
		}
		
		CoolUtil.playScrollSound();
	}
}

typedef JudgementPreset =
{
	var name:String;
	var marvWindow:Int;
	var sickWindow:Int;
	var goodWindow:Int;
	var badWindow:Int;
	var shitWindow:Int;
	var missWindow:Int;
}
