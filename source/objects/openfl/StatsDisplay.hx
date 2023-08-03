package objects.openfl;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.debug.DebuggerUtil;
import flixel.system.debug.Window;
import openfl.system.System;
import openfl.text.TextField;

class StatsDisplay extends Window
{
	var textField:TextField;
	var cacheCount:Int = 0;
	var currentTime:Float = 0;
	var times:Array<Float> = [];
	
	public function new()
	{
		super('Stats', null, 150, 50, false);
		
		var spacing = 2;
		
		textField = DebuggerUtil.createTextField(spacing, 15 + spacing, 0xaaffffff, 11);
		textField.multiline = true;
		addChild(textField);
		
		onResize(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
	}
	
	override function __enterFrame(deltaTime:Float)
	{
		currentTime += deltaTime;
		times.push(currentTime);
		
		while (times[0] < currentTime - 1000)
			times.shift();
			
		updateText();
		
		cacheCount = times.length;
	}
	
	// don't drag this lol
	override function onMouseDown(?_) {}
	
	public function onResize(width:Int, height:Int)
	{
		x = 10 + FlxG.scaleMode.offset.x;
		y = 10 + FlxG.scaleMode.offset.y;
	}
	
	function updateText()
	{
		var fps = getFPS();
		if (fps > FlxG.updateFramerate)
			fps = FlxG.updateFramerate;
		var mem = getMemory();
		
		var text = 'FPS: $fps\nMemory: $mem MB';
		if (textField.text != text)
			textField.text = text;
	}
	
	function getFPS()
	{
		return FlxMath.roundDecimal((times.length + cacheCount) / 2, 1);
	}
	
	function getMemory()
	{
		return FlxMath.roundDecimal((System.totalMemory / 1024) / 1000, 1);
	}
}
