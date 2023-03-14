package util.bindable;

import flixel.math.FlxMath;

class BindableFloat extends Bindable<Float>
{
	public var minValue:Float;
	public var maxValue:Float;

	public function new(defaultValue:Float, minValue:Float, maxValue:Float, ?action:Float->Float->Void)
	{
		super(defaultValue, action);
		this.minValue = minValue;
		this.maxValue = maxValue;
		value = defaultValue;
	}

	override function set_value(newValue:Float)
	{
		var oldValue = _value;

		_value = FlxMath.bound(newValue, minValue, maxValue);
		if (_value != oldValue)
			valueChanged.dispatch(_value, oldValue);

		return _value;
	}
}
