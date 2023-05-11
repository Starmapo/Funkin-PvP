package util.bindable;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

class Bindable<T> implements IFlxDestroyable
{
	public var valueChanged:FlxTypedSignal<T->T->Void> = new FlxTypedSignal();
	public var defaultValue:T;
	public var value(get, set):T;

	var _value:T;

	public function new(defaultValue:T, ?action:T->T->Void)
	{
		if (action != null)
			valueChanged.add(action);
		this.defaultValue = defaultValue;
		value = defaultValue;
	}

	public function triggerChange()
	{
		valueChanged.dispatch(value, value);
	}

	public function changeWithoutTrigger(newValue:T)
	{
		return _value = newValue;
	}

	public function toString()
	{
		return Std.string(value);
	}

	public function destroy()
	{
		FlxDestroyUtil.destroy(valueChanged);
		defaultValue = null;
		_value = null;
	}

	function get_value()
	{
		return _value;
	}

	function set_value(newValue:T)
	{
		var oldValue = _value;
		_value = newValue;
		valueChanged.dispatch(_value, oldValue);
		return _value;
	}
}
