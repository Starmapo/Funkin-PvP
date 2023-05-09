package data.scripts;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Matrix;
import openfl.geom.Point;

class FlxPointHelper
{
	public static inline function get(x:Float = 0, y:Float = 0):FlxPoint
	{
		return FlxPoint.get(x, y);
	}

	public static inline function weak(x:Float = 0, y:Float = 0):FlxPoint
	{
		return FlxPoint.weak(x, y);
	}

	public var x(get, set):Float;
	public var y(get, set):Float;

	public var dx(get, never):Float;
	public var dy(get, never):Float;
	public var length(get, set):Float;
	public var lengthSquared(get, never):Float;
	public var degrees(get, set):Float;
	public var radians(get, set):Float;
	public var rx(get, never):Float;
	public var ry(get, never):Float;
	public var lx(get, never):Float;
	public var ly(get, never):Float;

	public var point:FlxPoint;

	public function new(x:Float = 0, y:Float = 0)
	{
		point = new FlxPoint(x, y);
	}

	public inline function set(x:Float = 0, y:Float = 0):FlxPoint
	{
		return point.set(x, y);
	}

	public function put():Void
	{
		point.put();
	}

	public inline function putWeak():Void
	{
		point.putWeak();
	}

	public inline function equals(p:FlxBasePoint):Bool
	{
		return point.equals(p);
	}

	public function destroy() {}

	public inline function toString():String
	{
		return point.toString();
	}

	public inline function add(x:Float = 0, y:Float = 0):FlxPoint
	{
		return point.add(x, y);
	}

	public inline function addPoint(p:FlxPoint):FlxPoint
	{
		return point.addPoint(p);
	}

	public inline function subtract(x:Float = 0, y:Float = 0):FlxPoint
	{
		return point.subtract(x, y);
	}

	public inline function subtractPoint(p:FlxPoint):FlxPoint
	{
		return point.subtractPoint(p);
	}

	public inline function scale(x:Float, ?y:Float):FlxPoint
	{
		return point.scale(x, y);
	}

	public inline function scalePoint(p:FlxPoint):FlxPoint
	{
		return point.scalePoint(p);
	}

	public inline function scaleNew(k:Float):FlxPoint
	{
		return point.scaleNew(k);
	}

	public inline function addNew(p:FlxPoint):FlxPoint
	{
		return point.addNew(p);
	}

	public inline function subtractNew(p:FlxPoint):FlxPoint
	{
		return point.subtractNew(p);
	}

	public inline function copyFrom(p:FlxPoint):FlxPoint
	{
		return point.copyFrom(p);
	}

	public inline function copyFromFlash(p:Point):FlxPoint
	{
		return point.copyFromFlash(p);
	}

	public inline function copyTo(?p:FlxPoint):FlxPoint
	{
		return point.copyTo(p);
	}

	public inline function copyToFlash(?p:Point):Point
	{
		return point.copyToFlash(p);
	}

	public inline function addToFlash(p:Point):Point
	{
		return point.addToFlash(p);
	}

	public inline function subtractFromFlash(p:Point):Point
	{
		return point.subtractFromFlash(p);
	}

	public inline function floor():FlxPoint
	{
		return point.floor();
	}

	public inline function ceil():FlxPoint
	{
		return point.ceil();
	}

	public inline function round():FlxPoint
	{
		return point.round();
	}

	public inline function inCoords(x:Float, y:Float, width:Float, height:Float):Bool
	{
		return point.inCoords(x, y, width, height);
	}

	public inline function inRect(rect:FlxRect):Bool
	{
		return point.inRect(rect);
	}

	public inline function rotate(pivot:FlxPoint, degrees:Float):FlxPoint
	{
		return point.pivotDegrees(pivot, degrees);
	}

	public inline function pivotRadians(pivot:FlxPoint, radians:Float):FlxPoint
	{
		return point.pivotRadians(pivot, radians);
	}

	public inline function pivotDegrees(pivot:FlxPoint, degrees:Float):FlxPoint
	{
		return point.pivotDegrees(pivot, degrees);
	}

	public inline function distanceTo(p:FlxPoint):Float
	{
		return point.distanceTo(p);
	}

	public inline function radiansTo(p:FlxPoint):Float
	{
		return point.radiansTo(p);
	}

	public inline function radiansFrom(p:FlxPoint):Float
	{
		return point.radiansFrom(p);
	}

	public inline function degreesTo(p:FlxPoint):Float
	{
		return point.degreesTo(p);
	}

	public inline function degreesFrom(p:FlxPoint):Float
	{
		return point.degreesFrom(p);
	}

	public inline function angleBetween(p:FlxPoint):Float
	{
		return point.degreesTo(p);
	}

	public inline function transform(matrix:Matrix):FlxPoint
	{
		return point.transform(matrix);
	}

	public inline function dot(p:FlxPoint):Float
	{
		return point.dot(p);
	}

	public inline function dotProduct(p:FlxPoint):Float
	{
		return point.dotProduct(p);
	}

	public inline function dotProdWithNormalizing(p:FlxPoint):Float
	{
		return point.dotProdWithNormalizing(p);
	}

	public inline function isPerpendicular(p:FlxPoint):Bool
	{
		return point.isPerpendicular(p);
	}

	public inline function crossProductLength(p:FlxPoint):Float
	{
		return point.crossProductLength(p);
	}

	public inline function isParallel(p:FlxPoint):Bool
	{
		return point.isParallel(p);
	}

	public inline function isZero():Bool
	{
		return point.isZero();
	}

	public inline function zero():FlxPoint
	{
		return point.zero();
	}

	public inline function normalize():FlxPoint
	{
		return point.normalize();
	}

	public inline function isNormalized():Bool
	{
		return point.isNormalized();
	}

	public inline function rotateByRadians(rads:Float):FlxPoint
	{
		return point.rotateByRadians(rads);
	}

	public inline function rotateByDegrees(degs:Float):FlxPoint
	{
		return point.rotateByDegrees(degs);
	}

	public inline function rotateWithTrig(sin:Float, cos:Float):FlxPoint
	{
		return point.rotateWithTrig(sin, cos);
	}

	public inline function setPolarRadians(length:Float, radians:Float):FlxPoint
	{
		return point.setPolarRadians(length, radians);
	}

	public inline function setPolarDegrees(length:Float, degrees:Float):FlxPoint
	{
		return point.setPolarDegrees(length, degrees);
	}

	public inline function rightNormal(?p:FlxPoint):FlxPoint
	{
		return point.rightNormal(p);
	}

	public inline function leftNormal(?p:FlxPoint):FlxPoint
	{
		return point.leftNormal(p);
	}

	public inline function negate():FlxPoint
	{
		return point.negate();
	}

	public inline function negateNew():FlxPoint
	{
		return point.negateNew();
	}

	public inline function projectTo(p:FlxPoint, ?proj:FlxPoint):FlxPoint
	{
		return point.projectTo(p, proj);
	}

	public inline function projectToNormalized(p:FlxPoint, ?proj:FlxPoint):FlxPoint
	{
		return point.projectToNormalized(p, proj);
	}

	public inline function perpProduct(p:FlxPoint):Float
	{
		return point.perpProduct(p);
	}

	public inline function ratio(a:FlxPoint, b:FlxPoint, p:FlxPoint):Float
	{
		return point.ratio(a, b, p);
	}

	public inline function findIntersection(a:FlxPoint, b:FlxPoint, p:FlxPoint, ?intersection:FlxPoint):FlxPoint
	{
		return point.findIntersection(a, b, p, intersection);
	}

	public inline function findIntersectionInBounds(a:FlxPoint, b:FlxPoint, p:FlxPoint, ?intersection:FlxPoint):FlxPoint
	{
		return point.findIntersectionInBounds(a, b, p, intersection);
	}

	public inline function truncate(max:Float):FlxPoint
	{
		return point.truncate(max);
	}

	public inline function radiansBetween(p:FlxPoint):Float
	{
		return point.radiansBetween(p);
	}

	public inline function degreesBetween(p:FlxPoint):Float
	{
		return point.degreesBetween(p);
	}

	public inline function sign(a:FlxPoint, b:FlxPoint):Int
	{
		return point.sign(a, b);
	}

	public inline function dist(p:FlxPoint):Float
	{
		return point.dist(p);
	}

	public inline function distSquared(p:FlxPoint):Float
	{
		return point.distSquared(p);
	}

	public inline function bounce(normal:FlxPoint, bounceCoeff:Float = 1):FlxPoint
	{
		return point.bounce(normal, bounceCoeff);
	}

	public inline function bounceWithFriction(normal:FlxPoint, bounceCoeff:Float = 1, friction:Float = 0):FlxPoint
	{
		return point.bounceWithFriction(normal, bounceCoeff, friction);
	}

	public inline function isValid():Bool
	{
		return point.isValid();
	}

	public inline function clone(?p:FlxPoint):FlxPoint
	{
		return point.clone(p);
	}

	function get_x()
	{
		return point.x;
	}

	function set_x(value:Float)
	{
		return point.x = value;
	}

	function get_y()
	{
		return point.y;
	}

	function set_y(value:Float)
	{
		return point.y = value;
	}

	function get_dx()
	{
		return point.dx;
	}

	function get_dy()
	{
		return point.dy;
	}

	function get_length()
	{
		return point.length;
	}

	function set_length(value:Float)
	{
		return point.length = value;
	}

	function get_lengthSquared()
	{
		return point.lengthSquared;
	}

	function get_degrees()
	{
		return point.degrees;
	}

	function set_degrees(value:Float)
	{
		return point.degrees = value;
	}

	function get_radians()
	{
		return point.radians;
	}

	function set_radians(value:Float)
	{
		return point.radians = value;
	}

	function get_rx()
	{
		return point.rx;
	}

	function get_ry()
	{
		return point.ry;
	}

	function get_lx()
	{
		return point.lx;
	}

	function get_ly()
	{
		return point.ly;
	}
}
