package util.bindable;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

class BindableArray<T> extends Bindable<Array<T>>
{
	public var itemAdded:FlxTypedSignal<T->Void> = new FlxTypedSignal();
	public var itemRemoved:FlxTypedSignal<T->Void> = new FlxTypedSignal();
	public var arrayResized:FlxTypedSignal<Void->Void> = new FlxTypedSignal();

	public function new(defaultValue:Array<T>, ?action:Array<T>->Array<T>->Void)
	{
		super(defaultValue, action);
	}

	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(itemAdded);
		FlxDestroyUtil.destroy(itemRemoved);
		FlxDestroyUtil.destroy(arrayResized);
	}

	public function push(obj:T)
	{
		value.push(obj);
		itemAdded.dispatch(obj);
	}

	public function remove(obj:T)
	{
		value.remove(obj);
		itemRemoved.dispatch(obj);
	}

	public function resize(len:Int)
	{
		value.resize(len);
		arrayResized.dispatch();
	}
}
