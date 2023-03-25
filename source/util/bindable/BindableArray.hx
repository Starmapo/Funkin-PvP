package util.bindable;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

class BindableArray<T> extends Bindable<Array<T>>
{
	public var itemAdded:FlxTypedSignal<T->Void> = new FlxTypedSignal();
	public var itemRemoved:FlxTypedSignal<T->Void> = new FlxTypedSignal();
	public var multipleItemsAdded:FlxTypedSignal<Array<T>->Void> = new FlxTypedSignal();
	public var arrayCleared:FlxTypedSignal<Void->Void> = new FlxTypedSignal();

	public function new(defaultValue:Array<T>, ?action:Array<T>->Array<T>->Void)
	{
		super(defaultValue, action);
	}

	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(itemAdded);
		FlxDestroyUtil.destroy(itemRemoved);
		FlxDestroyUtil.destroy(multipleItemsAdded);
		FlxDestroyUtil.destroy(arrayCleared);
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

	public function pushMultiple(array:Array<T>)
	{
		for (obj in array)
			value.push(obj);
		multipleItemsAdded.dispatch(array);
	}

	public function clear()
	{
		value.resize(0);
		arrayCleared.dispatch();
	}
}
