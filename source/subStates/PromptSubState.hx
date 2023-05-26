package subStates;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class PromptSubState extends FlxSubState
{
	var promptBG:FlxUI9SliceSprite;
	var promptText:FlxUIText;
	var buttonGroup:FlxTypedGroup<FlxUIButton>;
	var camSubState:FlxCamera;
	var buttons:Array<ButtonData>;

	public function new(message:String, buttons:Array<ButtonData>)
	{
		super();
		this.buttons = buttons;

		camSubState = new FlxCamera();
		camSubState.bgColor = 0;
		camSubState.visible = false;
		FlxG.cameras.add(camSubState, false);
		cameras = [camSubState];

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.5)));

		promptText = new FlxUIText(0, 0, FlxG.width / 2, message);
		promptText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		promptText.screenCenter();

		promptBG = new FlxUI9SliceSprite(promptText.x - 5, promptText.y - 5, FlxUIAssets.IMG_CHROME_FLAT, new Rectangle(0, 0, (FlxG.width / 2) + 10, 0));
		add(promptBG);
		add(promptText);

		buttonGroup = new FlxTypedGroup();
		add(buttonGroup);

		createButtons();

		openCallback = onOpen;
		closeCallback = onClose;

		promptBG.resize(promptBG.width, promptText.height + 5 + buttonGroup.members[0].height + 10);
	}

	override function destroy()
	{
		super.destroy();
		promptBG = null;
		promptText = null;
		buttonGroup = null;
		camSubState = null;
	}

	function createButtons()
	{
		var curX:Float = 0;
		for (i in 0...buttons.length)
		{
			var button = new FlxUIButton(curX, promptText.y + promptText.height + 5, buttons[i].name, function()
			{
				if (buttons[i].callback != null)
					buttons[i].callback();

				close();
			});
			button.label.size = 16;
			button.resize(button.width, button.label.height);
			button.autoCenterLabel();
			buttonGroup.add(button);
			curX += button.width + 5;
		}
		CoolUtil.screenCenterGroup(buttonGroup, X);
	}

	function onOpen()
	{
		camSubState.visible = true;
	}

	function onClose()
	{
		camSubState.visible = false;
	}
}

class YesNoPrompt extends PromptSubState
{
	public function new(message:String, ?yesCallback:Void->Void, ?noCallback:Void->Void)
	{
		super(message, [
			{
				name: 'Yes',
				callback: yesCallback
			},
			{
				name: 'No',
				callback: noCallback
			}
		]);
	}
}

typedef ButtonData =
{
	var name:String;
	var ?callback:Void->Void;
}
