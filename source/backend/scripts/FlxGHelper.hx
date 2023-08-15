package backend.scripts;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxVersion;
import flixel.system.frontEnds.BitmapFrontEnd;
import flixel.system.frontEnds.BitmapLogFrontEnd;
import flixel.system.frontEnds.CameraFrontEnd;
import flixel.system.frontEnds.ConsoleFrontEnd;
import flixel.system.frontEnds.DebuggerFrontEnd;
import flixel.system.frontEnds.InputFrontEnd;
import flixel.system.frontEnds.LogFrontEnd;
import flixel.system.frontEnds.PluginFrontEnd;
import flixel.system.frontEnds.SignalFrontEnd;
import flixel.system.frontEnds.VCRFrontEnd;
import flixel.system.frontEnds.WatchFrontEnd;
import flixel.system.scaleModes.BaseScaleMode;
import openfl.display.Stage;
#if FLX_MOUSE
import flixel.input.mouse.FlxMouse;
#end
#if FLX_TOUCH
import flixel.input.touch.FlxTouchManager;
#end
#if FLX_POINTER_INPUT
import flixel.input.FlxSwipe;
#end
#if FLX_KEYBOARD
import flixel.input.keyboard.FlxKeyboard;
#end
#if FLX_GAMEPAD
import flixel.input.gamepad.FlxGamepadManager;
#end
#if android
import flixel.input.android.FlxAndroidKeys;
#end
#if FLX_ACCELEROMETER
import flixel.input.FlxAccelerometer;
#end
#if html5
import flixel.system.frontEnds.HTML5FrontEnd;
#end
#if FLX_SOUND_SYSTEM
import flixel.system.frontEnds.SoundFrontEnd;
#end

// TODO: this can probably be done easier with a macro

/**
	This is a fake version of `FlxG` used for scripts. It prevents access to `save` and `openURL`, for security measures.
**/
class FlxGHelper
{
	public static var autoPause(get, set):Bool;
	
	static inline function get_autoPause()
		return FlxG.autoPause;
		
	static inline function set_autoPause(value)
		return FlxG.autoPause = value;
		
	public static var fixedTimestep(get, set):Bool;
	
	static inline function get_fixedTimestep()
		return FlxG.autoPause;
		
	static inline function set_fixedTimestep(value)
		return FlxG.autoPause = value;
		
	public static var timeScale(get, set):Float;
	
	static inline function get_timeScale()
		return FlxG.timeScale;
		
	static inline function set_timeScale(value)
		return FlxG.timeScale = value;
		
	public static var worldDivisions(get, set):Int;
	
	static inline function get_worldDivisions()
		return FlxG.worldDivisions;
		
	static inline function set_worldDivisions(value)
		return FlxG.worldDivisions = value;
		
	public static var camera(get, set):FlxCamera;
	
	static inline function get_camera()
		return FlxG.camera;
		
	static inline function set_camera(value)
		return FlxG.camera = value;
		
	public static var VERSION(get, never):FlxVersion;
	
	static inline function get_VERSION()
		return FlxG.VERSION;
		
	public static var stage(get, never):Stage;
	
	static inline function get_stage()
		return FlxG.stage;
		
	public static var state(get, never):FlxState;
	
	static inline function get_state()
		return FlxG.state;
		
	public static var updateFramerate(get, set):Int;
	
	static inline function get_updateFramerate()
		return FlxG.updateFramerate;
		
	static inline function set_updateFramerate(value)
		return FlxG.updateFramerate = value;
		
	public static var drawFramerate(get, set):Int;
	
	static inline function get_drawFramerate()
		return FlxG.drawFramerate;
		
	static inline function set_drawFramerate(value)
		return FlxG.drawFramerate = value;
		
	public static var onMobile(get, never):Bool;
	
	static inline function get_onMobile()
		return FlxG.onMobile;
		
	public static var renderMethod(get, never):FlxRenderMethod;
	
	static inline function get_renderMethod()
		return FlxG.renderMethod;
		
	public static var renderBlit(get, never):Bool;
	
	static inline function get_renderBlit()
		return FlxG.renderBlit;
		
	public static var renderTile(get, never):Bool;
	
	static inline function get_renderTile()
		return FlxG.renderTile;
		
	public static var elapsed(get, never):Float;
	
	static inline function get_elapsed()
		return FlxG.elapsed;
		
	public static var maxElapsed(get, set):Float;
	
	static inline function get_maxElapsed()
		return FlxG.maxElapsed;
		
	static inline function set_maxElapsed(value)
		return FlxG.maxElapsed = value;
		
	public static var width(get, never):Int;
	
	static inline function get_width()
		return FlxG.width;
		
	public static var height(get, never):Int;
	
	static inline function get_height()
		return FlxG.height;
		
	public static var scaleMode(get, set):BaseScaleMode;
	
	static inline function get_scaleMode()
		return FlxG.scaleMode;
		
	static inline function set_scaleMode(value)
		return FlxG.scaleMode = value;
		
	public static var fullscreen(get, set):Bool;
	
	static inline function get_fullscreen()
		return FlxG.fullscreen;
		
	static inline function set_fullscreen(value)
		return FlxG.fullscreen = value;
		
	public static var worldBounds(get, never):FlxRect;
	
	static inline function get_worldBounds()
		return FlxG.worldBounds;
		
	public static var random(get, never):FlxRandom;
	
	static inline function get_random()
		return FlxG.random;
		
	#if FLX_MOUSE
	public static var mouse(get, never):FlxMouse;
	
	static inline function get_mouse()
		return FlxG.mouse;
	#end
	
	#if FLX_TOUCH
	public static var touches(get, never):FlxTouchManager;
	
	static inline function get_touches()
		return FlxG.touches;
	#end
	
	#if FLX_POINTER_INPUT
	public static var swipes(get, never):Array<FlxSwipe>;
	
	static inline function get_swipes()
		return FlxG.swipes;
	#end
	
	#if FLX_KEYBOARD
	public static var keys(get, never):FlxKeyboard;
	
	static inline function get_keys()
		return FlxG.keys;
	#end
	
	#if FLX_GAMEPAD
	public static var gamepads(get, never):FlxGamepadManager;
	
	static inline function get_gamepads()
		return FlxG.gamepads;
	#end
	
	#if android
	public static var android(get, never):FlxAndroidKeys;
	
	static inline function get_android()
		return FlxG.android;
	#end
	
	#if FLX_ACCELEROMETER
	public static var accelerometer(get, never):FlxAccelerometer;
	
	static inline function get_accelerometer()
		return FlxG.accelerometer;
	#end
	
	#if js
	public static var html5(get, never):HTML5FrontEnd;
	
	static inline function get_html5()
		return FlxG.html5;
	#end
	
	public static var inputs(get, never):InputFrontEnd;
	
	static inline function get_inputs()
		return FlxG.inputs;
		
	public static var console(get, never):ConsoleFrontEnd;
	
	static inline function get_console()
		return FlxG.console;
		
	public static var log(get, never):LogFrontEnd;
	
	static inline function get_log()
		return FlxG.log;
		
	public static var bitmapLog(get, never):BitmapLogFrontEnd;
	
	static inline function get_bitmapLog()
		return FlxG.bitmapLog;
		
	public static var watch(get, never):WatchFrontEnd;
	
	static inline function get_watch()
		return FlxG.watch;
		
	public static var debugger(get, never):DebuggerFrontEnd;
	
	static inline function get_debugger()
		return FlxG.debugger;
		
	public static var vcr(get, never):VCRFrontEnd;
	
	static inline function get_vcr()
		return FlxG.vcr;
		
	public static var bitmap(get, never):BitmapFrontEnd;
	
	static inline function get_bitmap()
		return FlxG.bitmap;
		
	public static var cameras(get, never):CameraFrontEnd;
	
	static inline function get_cameras()
		return FlxG.cameras;
		
	public static var plugins(get, never):PluginFrontEnd;
	
	static inline function get_plugins()
		return FlxG.plugins;
		
	public static var initialWidth(get, never):Int;
	
	static inline function get_initialWidth()
		return FlxG.initialWidth;
		
	public static var initialHeight(get, never):Int;
	
	static inline function get_initialHeight()
		return FlxG.initialHeight;
		
	#if FLX_SOUND_SYSTEM
	public static var sound(get, never):SoundFrontEnd;
	
	static inline function get_sound()
		return FlxG.sound;
	#end
	
	public static var signals(get, never):SignalFrontEnd;
	
	static inline function get_signals()
		return FlxG.signals;
		
	public static inline function resizeGame(width, height)
		FlxG.resizeGame(width, height);
		
	public static inline function resizeWindow(width, height)
		FlxG.resizeWindow(width, height);
		
	public static inline function resetGame()
		FlxG.resetGame();
		
	public static inline function switchState(nextState)
		FlxG.switchState(nextState);
		
	public static inline function resetState()
		FlxG.resetState();
		
	public static inline function overlap(?objectOrGroup1, ?objectOrGroup2, ?notifyCallback, ?processCallback)
		return FlxG.overlap(objectOrGroup1, objectOrGroup2, notifyCallback, processCallback);
		
	public static inline function pixelPerfectOverlap(sprite1, sprite2, alphaTolerance = 255, ?camera)
		return FlxG.pixelPerfectOverlap(sprite1, sprite2, alphaTolerance, camera);
		
	public static inline function collide(?objectOrGroup1, ?objectOrGroup2, ?notifyCallback)
		return FlxG.collide(objectOrGroup1, objectOrGroup2, notifyCallback);
		
	public static inline function addChildBelowMouse(child, indexModifier = 0)
		return FlxG.addChildBelowMouse(child, indexModifier);
		
	public static inline function removeChild(child)
		return FlxG.removeChild(child);
		
	public static inline function addPostProcess(postProcess)
		return FlxG.addPostProcess(postProcess);
		
	public static inline function removePostProcess(postProcess)
		return FlxG.removePostProcess(postProcess);
}
