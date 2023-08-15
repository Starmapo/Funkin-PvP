package subStates.editors;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import objects.editors.EditorInputText;
import objects.editors.EditorNumericStepper;
import objects.editors.EditorPanel;

using StringTools;

// FROM YOSHI ENGINE
class ColorPickerSubState extends FNFSubState
{
	public var color:FlxColor;
	
	var callback:FlxColor->Void;
	var colorSprite:FlxSprite;
	var redNumeric:EditorNumericStepper;
	var greenNumeric:EditorNumericStepper;
	var blueNumeric:EditorNumericStepper;
	var originalColor:FlxColor;
	var colorInput:EditorInputText;
	var tab:FlxUI;
	var uiTabs:EditorPanel;
	
	public function new(startingColor:FlxColor, ?callback:FlxColor->Void)
	{
		super();
		color = startingColor;
		this.callback = callback;
		checkObjects = true;
	}
	
	override function create()
	{
		createCamera();
		
		uiTabs = new EditorPanel([{name: "colorPicker", label: 'Select a color...'}]);
		
		tab = uiTabs.createTab("colorPicker");
		
		colorSprite = new FlxSprite(175, 10).makeGraphic(70, 55, 0xFFFFFFFF);
		colorSprite.pixels.lock();
		for (x in 0...colorSprite.pixels.width)
		{
			colorSprite.pixels.setPixel32(x, 0, 0xFF000000);
			colorSprite.pixels.setPixel32(x, 1, 0xFF000000);
			colorSprite.pixels.setPixel32(x, 53, 0xFF000000);
			colorSprite.pixels.setPixel32(x, 54, 0xFF000000);
		}
		for (y in 0...colorSprite.pixels.height)
		{
			colorSprite.pixels.setPixel32(0, y, 0xFF000000);
			colorSprite.pixels.setPixel32(1, y, 0xFF000000);
			colorSprite.pixels.setPixel32(68, y, 0xFF000000);
			colorSprite.pixels.setPixel32(69, y, 0xFF000000);
		}
		colorSprite.pixels.unlock();
		tab.add(colorSprite);
		
		var rgbLabel = new FlxUIText(10, 75, 400, "RGB");
		rgbLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		
		redNumeric = new EditorNumericStepper(10, 75 + rgbLabel.height, 1, 0, 0, 255, 0, camSubState);
		greenNumeric = new EditorNumericStepper(20 + redNumeric.width, redNumeric.y, 1, 0, 0, 255, 0, camSubState);
		blueNumeric = new EditorNumericStepper(30 + greenNumeric.width + redNumeric.width, redNumeric.y, 1, 0, 0, 255, 0, camSubState);
		redNumeric.valueChanged.add(function(value, lastValue)
		{
			color.red = Std.int(value);
			updateColor(redNumeric);
		});
		greenNumeric.valueChanged.add(function(value, lastValue)
		{
			color.green = Std.int(value);
			updateColor(greenNumeric);
		});
		blueNumeric.valueChanged.add(function(value, lastValue)
		{
			color.blue = Std.int(value);
			updateColor(blueNumeric);
		});
		
		var hexLabel = new FlxUIText(blueNumeric.x + blueNumeric.width + 10, rgbLabel.y, 400, "Hex");
		hexLabel.setBorderStyle(OUTLINE, FlxColor.BLACK);
		
		colorInput = new EditorInputText(hexLabel.x, hexLabel.y + hexLabel.height, 0, null, 8, true, camSubState);
		colorInput.textChanged.add(function(text, lastText)
		{
			if (text.length < 1)
			{
				colorInput.text = lastText;
				return;
			}
			
			text = text.trim();
			if (!text.startsWith('#') && !text.startsWith('0x'))
				text = '#' + text;
			var generatedColor = FlxColor.fromString(text);
			if (generatedColor == null)
			{
				colorInput.text = lastText;
				return;
			}
			
			generatedColor.alpha = 255;
			color = generatedColor;
			updateColor();
		});
		
		updateColor();
		
		tab.add(rgbLabel);
		tab.add(redNumeric);
		tab.add(greenNumeric);
		tab.add(blueNumeric);
		tab.add(hexLabel);
		tab.add(colorInput);
		
		var okButton = new FlxUIButton(10, redNumeric.y + redNumeric.height + 10, "OK", function()
		{
			if (callback != null)
				callback(color);
			close();
		});
		tab.add(okButton);
		
		uiTabs.resize(420, okButton.y + 50);
		uiTabs.screenCenter();
		uiTabs.addGroup(tab);
		add(uiTabs);
		
		var closeButton = new FlxUIButton(uiTabs.x + uiTabs.width - 24, uiTabs.y + 4, "X", function()
		{
			color = originalColor;
			close();
		});
		closeButton.resize(20, 20);
		closeButton.color = FlxColor.RED;
		closeButton.label.color = FlxColor.WHITE;
		add(closeButton);

		super.create();
	}
	
	override function destroy()
	{
		super.destroy();
		callback = null;
		colorSprite = null;
		redNumeric = null;
		greenNumeric = null;
		blueNumeric = null;
		colorInput = null;
	}
	
	override function onOpen()
	{
		updateColor();
		originalColor = color;
		super.onOpen();
	}
	
	function updateColor(?e:Dynamic, pick:Bool = true)
	{
		colorSprite.color = color;
		var ignore = [redNumeric, greenNumeric, blueNumeric];
		if (!ignore.contains(e))
		{
			redNumeric.value = color.red;
			greenNumeric.value = color.green;
			blueNumeric.value = color.blue;
		}
		colorInput.text = color.toHexString(false, false);
	}
}
