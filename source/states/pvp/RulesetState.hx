package states.pvp;

import backend.Music;
import backend.game.Judgement;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import objects.menus.VoidBG;
import objects.menus.lists.SettingsMenuList;
import states.menus.MainMenuState;
import subStates.pvp.JudgementPresetsSubState;

class RulesetState extends FNFState
{
	static var lastSelected:Int = 0;
	
	public var items:SettingsMenuList;
	
	var camScroll:FlxCamera;
	var camOver:FlxCamera;
	var iconScroll:FlxBackdrop;
	var transitioning:Bool = true;
	var descBG:FlxSprite;
	var descText:FlxText;
	var descTween:FlxTween;
	var camFollow:FlxObject;
	var stateText:FlxText;
	var judgementPresetsSubState:JudgementPresetsSubState;
	
	override function create()
	{
		DiscordClient.changePresence(null, "Ruleset Options");
		
		transIn = transOut = null;
		destroySubStates = false;
		
		FlxG.cameras.reset(new FNFCamera());
		camScroll = new FlxCamera();
		camScroll.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.5);
		FlxG.cameras.add(camScroll, false);
		camOver = new FlxCamera();
		camOver.bgColor = 0;
		FlxG.cameras.add(camOver, false);
		
		judgementPresetsSubState = new JudgementPresetsSubState(this);
		
		camFollow = new FlxObject(FlxG.width / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.1);
		add(camFollow);
		
		var bg = CoolUtil.createMenuBG('menuBGDesat');
		bg.color = 0xFF21007F;
		add(bg);
		
		add(new VoidBG());
		
		stateText = new FlxText(0, 0, 0, 'Ruleset');
		stateText.setFormat(Paths.FONT_PHANTOMMUFF, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		stateText.screenCenter(X);
		stateText.scrollFactor.set();
		stateText.cameras = [camOver];
		camScroll.height = Math.ceil(stateText.height);
		stateText.y = camScroll.y -= camScroll.height;
		
		iconScroll = new FlxBackdrop(Paths.getImage('menus/pvp/iconScroll'));
		iconScroll.alpha = 0.5;
		iconScroll.cameras = [camScroll];
		iconScroll.velocity.set(25, 25);
		iconScroll.scale.set(0.5, 0.5);
		iconScroll.antialiasing = Settings.antialiasing;
		
		add(iconScroll);
		add(stateText);
		
		descBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBG.scrollFactor.set();
		descBG.alpha = 0.8;
		descBG.cameras = [camOver];
		
		descText = new FlxText(0, 0, FlxG.width - 10);
		descText.setFormat(Paths.FONT_VCR, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.cameras = [camOver];
		
		items = new SettingsMenuList();
		items.onChange.add(onChange);
		items.controlsEnabled = false;
		add(items);
		
		var duration = Main.getTransitionTime();
		
		addSetting({
			name: 'singleSongSelection',
			displayName: 'Single Song Selection',
			description: "If enabled, both players will pick one song instead of randomly picking from both players' selections.",
			type: CHECKBOX
		});
		addSetting({
			name: 'playbackRate',
			displayName: 'Playback Rate',
			description: "Change how slow or fast the song plays.",
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'x';
			},
			minValue: 0.5,
			maxValue: 2,
			decimals: 2,
			changeAmount: 0.05,
			holdDelay: 0.05
		});
		addSetting({
			name: 'noSliderVelocity',
			displayName: 'No Slider Velocities',
			description: "If enabled, slider velocities are removed from maps that have them.",
			type: CHECKBOX
		});
		addSetting({
			name: 'mirrorNotes',
			displayName: 'Mirror Notes',
			description: "If enabled, the map is flipped horizontally.",
			type: CHECKBOX
		});
		addSetting({
			name: 'noLongNotes',
			displayName: 'No Long Notes',
			description: "If enabled, long notes are converted into regular notes.",
			type: CHECKBOX
		}, function()
		{
			if (Settings.noLongNotes)
			{
				forceSettingOff('Full Long Notes');
				forceSettingOff('Inverse Notes');
			}
		});
		addSetting({
			name: 'fullLongNotes',
			displayName: 'Full Long Notes',
			description: "If enabled, every note in the map becomes a long note.",
			type: CHECKBOX
		}, function()
		{
			if (Settings.fullLongNotes)
			{
				forceSettingOff('No Long Notes');
				forceSettingOff('Inverse Notes');
			}
		});
		addSetting({
			name: 'inverse',
			displayName: 'Inverse Notes',
			description: "If enabled, regular notes are converted into long notes and long notes are replaced by gaps.",
			type: CHECKBOX
		}, function()
		{
			if (Settings.inverse)
			{
				forceSettingOff('No Long Notes');
				forceSettingOff('Full Long Notes');
			}
		});
		addSetting({
			name: 'randomize',
			displayName: 'Randomize Map',
			description: "If enabled, note lanes are shuffled around randomly.",
			type: CHECKBOX
		});
		addSetting({
			name: 'ghostTapping',
			displayName: 'Ghost Tapping',
			description: "If enabled, you won't get misses from pressing a key without there being a note nearby.",
			type: CHECKBOX
		});
		addSetting({
			name: 'marvWindow',
			displayName: '"Marvelous" Hit Window',
			description: 'Change the amount of milliseconds you have for scoring a "Marvelous" rating.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			name: 'sickWindow',
			displayName: '"Sick" Hit Window',
			description: 'Change the amount of milliseconds you have for scoring a "Sick" rating.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			name: 'goodWindow',
			displayName: '"Good" Hit Window',
			description: 'Change the amount of milliseconds you have for scoring a "Good" rating.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			name: 'badWindow',
			displayName: '"Bad" Hit Window',
			description: 'Change the amount of milliseconds you have for scoring a "Bad" rating.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			name: 'shitWindow',
			displayName: '"Shit" Hit Window',
			description: 'Change the amount of milliseconds you have for scoring a "Shit" rating.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			name: 'missWindow',
			displayName: 'Miss Window',
			description: 'Change the amount of milliseconds you have to hit a note.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'ms';
			},
			minValue: 1,
			maxValue: 500
		});
		addSetting({
			displayName: 'Judgement Presets',
			description: "Choose a preset for judgement hit windows.",
			type: ACTION
		}, function()
		{
			openSubState(judgementPresetsSubState);
		});
		addSetting({
			name: 'comboBreakJudgement',
			displayName: 'Combo Break Judgement',
			description: 'Select which judgement causes a player to lose their combo.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return (value : Judgement).getName();
			},
			minValue: 1,
			maxValue: 5,
			holdDelay: 0.05,
			wrap: true
		});
		/*
			addSetting({
				name: 'randomEvents',
				displayName: 'Random Events',
				description: "Whether random events are enabled to spice up the gameplay.",
				type: CHECKBOX
			});
		 */
		addSetting({
			name: 'canDie',
			displayName: 'Can Die',
			description: "If enabled, players can die by losing all of their health.",
			type: CHECKBOX
		});
		addSetting({
			name: 'healthGain',
			displayName: 'Health Gain Multiplier',
			description: 'Change how much health you gain after successfully hitting a note.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'x';
			},
			minValue: 0,
			maxValue: 5,
			decimals: 2,
			changeAmount: 0.05,
			holdDelay: 0.05
		});
		addSetting({
			name: 'healthLoss',
			displayName: 'Health Loss Multiplier',
			description: 'Change how much health you lose after missing or badly hitting a note.',
			type: NUMBER,
			displayFunction: function(value)
			{
				return value + 'x';
			},
			minValue: 0.5,
			maxValue: 5,
			decimals: 2,
			changeAmount: 0.05,
			holdDelay: 0.05
		});
		addSetting({
			name: 'noMiss',
			displayName: 'No Miss',
			description: "If enabled, players die instantly if they get a combo break.",
			type: CHECKBOX
		});
		addSetting({
			name: 'winCondition',
			displayName: 'Win Condition',
			description: "Choose the win condition.",
			type: STRING,
			options: [WinCondition.SCORE, WinCondition.ACCURACY, WinCondition.MISSES]
		});
		addSetting({
			displayName: 'OK',
			description: "",
			type: ACTION,
		}, function()
		{
			exitTransition(false, function(_)
			{
				FlxG.switchState(new SongSelectState());
			});
			FlxFlicker.flicker(items.selectedItem, duration, 0.06, true, false);
			CoolUtil.playConfirmSound();
		});
		
		items.selectItem(lastSelected);
		FlxG.camera.snapToTarget();
		
		add(descBG);
		add(descText);
		
		FlxG.camera.zoom = 3;
		FlxTween.tween(camScroll, {y: 0}, duration, {ease: FlxEase.expoOut});
		FlxTween.tween(FlxG.camera, {zoom: 1}, duration, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				transitioning = false;
				items.controlsEnabled = true;
			}
		});
		camOver.fade(FlxColor.BLACK, duration, true, null, true);
		
		if (!Music.playing)
			Music.playPvPMusic(duration);
			
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		if (!transitioning && Controls.anyJustPressed(BACK))
		{
			exitTransition(true, function(_)
			{
				FlxG.switchState(new MainMenuState());
			});
			CoolUtil.playCancelSound();
		}
		
		super.update(elapsed);
		
		// prevent overflow (it would probably take an eternity for that to happen but you can never be too safe)
		if (iconScroll.x >= 300)
		{
			iconScroll.x %= 300;
		}
		if (iconScroll.y >= 300)
		{
			iconScroll.y %= 300;
		}
		
		stateText.y = camScroll.y;
		descBG.y = descText.y - 2;
	}
	
	override function destroy()
	{
		super.destroy();
		camScroll = null;
		camOver = null;
		iconScroll = null;
		items = null;
		descBG = null;
		descText = null;
		descTween = null;
		camFollow = null;
		stateText = null;
		judgementPresetsSubState = FlxDestroyUtil.destroy(judgementPresetsSubState);
	}
	
	function onChange(item:SettingsMenuItem)
	{
		updateCamFollow(item);
		updateDesc(item, true);
		lastSelected = item.ID;
	}
	
	function updateCamFollow(item:SettingsMenuItem)
	{
		var midpoint = item.getMidpoint();
		camFollow.y = midpoint.y;
		midpoint.put();
	}
	
	function updateDesc(item:SettingsMenuItem, tween:Bool = false)
	{
		descText.text = item.data.description;
		descText.screenCenter(X);
		descText.y = FlxG.height - descText.height - 10;
		descBG.setGraphicSize(Std.int(descText.width + 4), Std.int(descText.height + 4));
		descBG.updateHitbox();
		descBG.setPosition(descText.x - 2, descText.y - 2);
		descBG.visible = descText.visible = descText.text.length > 0;
		
		if (tween)
			tweenDesc();
	}
	
	function tweenDesc()
	{
		if (descTween != null)
			descTween.cancel();
			
		descText.y -= 10;
		descBG.y = descText.y - 2;
		descTween = FlxTween.tween(descText, {y: descText.y + 10}, 0.2, {
			onComplete: function(_)
			{
				descTween = null;
			}
		});
	}
	
	function addSetting(data:SettingData, ?callback:Void->Void)
	{
		var item = new SettingsMenuItem(0, items.length * 140, data.displayName, callback, data);
		return items.addItem(item.name, item);
	}
	
	function exitTransition(fadeMusic:Bool, onComplete:FlxTween->Void)
	{
		Settings.saveData();
		if (descTween != null)
			descTween.cancel();
		transitioning = true;
		items.controlsEnabled = false;
		var duration = Main.getTransitionTime();
		if (fadeMusic && FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(duration);
		FlxTween.tween(camScroll, {y: -camScroll.height}, duration / 2, {ease: FlxEase.expoIn});
		FlxTween.tween(descText, {y: FlxG.height}, duration / 2, {ease: FlxEase.expoIn});
		FlxTween.tween(FlxG.camera, {zoom: 5}, duration, {
			ease: FlxEase.expoIn,
			onComplete: function(twn)
			{
				if (fadeMusic)
					Music.stopMusic();
					
				onComplete(twn);
			}
		});
		camOver.fade(FlxColor.BLACK, duration, false, null, true);
	}
	
	function forceSettingOff(name:String)
	{
		var item = items.getItemByName(name);
		if (item != null && item.data.type == CHECKBOX && item.value)
			item.value = false;
	}
}
