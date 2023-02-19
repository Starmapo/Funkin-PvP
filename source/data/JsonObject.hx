package data;

/**
	Basically this just allows for easily reading JSON files.
**/
class JsonObject
{
	/**
	 * Returns a property if it exists on the JSON file, or `defaultValue` if it doesn't.
	 * @param value The value from the JSON file.
	 * @param defaultValue A value to return if the value doesn't exist on the JSON file.
	 */
	function readProperty<T>(value:T, defaultValue:T):T
	{
		if (value == null)
			return defaultValue;

		return value;
	}

	/**
		Returns an integer property if it exists on the JSON file, or `defaultValue` if it doesn't.
	**/
	function readInt(value:Null<Int>, defaultValue:Int = 0, ?min:Int, ?max:Int):Int
	{
		var int:Null<Int> = readProperty(value, defaultValue);
		if (int < min)
			int = min;
		if (int > max)
			int = max;
		return int;
	}

	/**
		Returns a float property if it exists on the JSON file, or `defaultValue` if it doesn't.
	**/
	function readFloat(value:Null<Float>, defaultValue:Float = 0, ?min:Float, ?max:Float, ?decimals:Int):Null<Float>
	{
		return readProperty(value, defaultValue);
	}

	/**
		Returns a boolean property if it exists on the JSON file, or `defaultValue` if it doesn't.
	**/
	function readBool(value:Null<Bool>, defaultValue:Bool = false):Null<Bool>
	{
		return readProperty(value, defaultValue) == true;
	}

	/**
		Returns a string property if it exists on the JSON file, or `defaultValue` if it doesn't.
	**/
	function readString(value:String, defaultValue:String = ''):String
	{
		return readProperty(value, defaultValue);
	}

	/**
		Returns an array property if it exists on the JSON file, or `defaultValue` if it doesn't.
		You'll have to cast the array to use it with another type.
	**/
	function readArray(value:Array<Any>, ?defaultValue:Array<Any>):Array<Any>
	{
		if (defaultValue == null)
			defaultValue = [];

		var array:Array<Any> = readProperty(value, defaultValue);
		return array;
	}

	/**
		Returns an object property if it exists on the JSON file, or `defaultValue` if it doesn't.
	**/
	function readObject(value:Dynamic, defaultValue:Dynamic):Dynamic
	{
		return readProperty(value, defaultValue);
	}

	/**
		Returns if a property isn't `null`.
	**/
	function hasProperty(value:Dynamic)
	{
		return value != null;
	}
}
