package backend.bindable;

import flixel.math.FlxMath;

class BindableInt extends Bindable<Int>
{
	public var minValue:Int;
	public var maxValue:Int;
	
	public function new(defaultValue:Int, minValue:Int, maxValue:Int, ?action:Int->Int->Void)
	{
		super(defaultValue, action);
		this.minValue = minValue;
		this.maxValue = maxValue;
		value = defaultValue;
	}
	
	override function set_value(newValue:Int)
	{
		var oldValue = _value;
		
		_value = Std.int(FlxMath.bound(newValue, minValue, maxValue));
		if (_value != oldValue)
			valueChanged.dispatch(_value, oldValue);
			
		return _value;
	}
}
