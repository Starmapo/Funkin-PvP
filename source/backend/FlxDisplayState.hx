package backend;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import openfl.display.DisplayObjectContainer;

/**
	A `DisplayObject` that behaves like a `FlxState`, meaning you can add Flixel objects to it.
**/
class FlxDisplayState extends DisplayObjectContainer
{
	public var members(get, never):Array<FlxBasic>;
	public var length(get, never):Int;
	
	var camera:FlxCamera;
	var group:FlxGroup;
	
	public function new()
	{
		super();
		
		camera = new FlxCamera();
		camera.bgColor = 0;
		updateLayer();
		
		group = new FlxGroup();
		group.cameras = [camera];
		
		FlxG.signals.postUpdate.add(onPostUpdate);
		FlxG.signals.postDraw.add(onPostDraw);
		FlxG.signals.postStateSwitch.add(onPostStateSwitch);
		FlxG.signals.gameResized.add(onResize);
	}
	
	public function add(basic:FlxBasic)
		return group.add(basic);
		
	public function insert(position:Int, object:FlxBasic)
		return group.insert(position, object);
		
	public function remove(basic:FlxBasic, splice = false)
		return group.remove(basic, splice);
		
	public function replace(oldObject:FlxBasic, newObject:FlxBasic)
		return group.replace(oldObject, newObject);
		
	public inline function sort(func:(Int, FlxBasic, FlxBasic) -> Int, order = FlxSort.ASCENDING)
		group.sort(func, order);
		
	public function clear()
		group.clear();
		
	public function destroyMembers()
		group.destroyMembers();
		
	public function killMembers()
		group.killMembers();
		
	public function destroy()
	{
		group = FlxDestroyUtil.destroy(group);
		if (camera != null)
		{
			FlxDestroyUtil.removeChild(this, camera.flashSprite);
			camera = FlxDestroyUtil.destroy(camera);
		}
	}
	
	function updateLayer()
	{
		@:privateAccess
		var inputIndex = FlxG.game.getChildIndex(FlxG.game._inputContainer);
		var spriteIndex = FlxG.game.getChildIndex(camera.flashSprite);
		if (spriteIndex != inputIndex - 1 || spriteIndex < 0)
			FlxG.game.addChildAt(camera.flashSprite, inputIndex);
	}
	
	function onPostUpdate()
	{
		group.update(FlxG.elapsed);
		
		if (camera.exists && camera.active)
			camera.update(FlxG.elapsed);
			
		updateLayer();
	}
	
	@:access(flixel.system.frontEnds.CameraFrontEnd)
	function onPostDraw()
	{
		if (!camera.exists || !camera.visible)
			return;
			
		var oldList = FlxG.cameras.list;
		FlxG.cameras.list = [camera];
		
		FlxG.cameras.lock();
		
		group.draw();
		
		FlxG.cameras.render();
		FlxG.cameras.unlock();
		
		FlxG.cameras.list = oldList;
	}
	
	function onPostStateSwitch()
	{
		updateLayer();
	}
	
	function onResize(_, _)
	{
		camera.onResize();
	}
	
	function get_members()
		return group.members;
		
	function get_length()
		return group.length;
}
