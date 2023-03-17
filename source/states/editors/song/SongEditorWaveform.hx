package states.editors.song;

import data.Settings;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.geom.Rectangle;

class SongEditorWaveform extends FlxBasic
{
	var state:SongEditorState;
	var slices:Array<SongEditorWaveformSlice> = [];
	var slicePool:Array<SongEditorWaveformSlice> = [];
	var lastPooledSliceIndex:Int = -1;
	var sliceSize:Int;
	var waveformData:Array<Array<Array<Float>>>;
	var sound:FlxSound;
	var buffer:AudioBuffer;
	var bytes:Bytes;

	public function new(state:SongEditorState)
	{
		super();
		this.state = state;

		generateWaveform();

		state.songSeeked.add(onSongSeeked);
		state.rateChanged.add(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.add(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.add(onScaleSpeedWithRateChanged);
	}

	override function update(elapsed:Float)
	{
		var i = slicePool.length - 1;
		while (i >= 0)
		{
			var slice = slicePool[i];
			if (!slice.sliceOnScreen())
				slicePool.remove(slice);
			i--;
		}

		i = lastPooledSliceIndex + 1;
		while (i < slices.length)
		{
			var slice = slices[i];
			if (slice.sliceOnScreen())
			{
				slicePool.push(slice);
				lastPooledSliceIndex = i;
			}
			i++;
		}
	}

	override function draw()
	{
		for (i in 0...slicePool.length)
		{
			var slice = slicePool[i];
			if (slice.isOnScreen())
			{
				slice.draw();
			}
		}
	}

	override function destroy()
	{
		if (slices.length > 0)
		{
			for (slice in slices)
			{
				if (slice != null)
					slice.destroy();
			}
		}
		slices.resize(0);
		super.destroy();
		state.songSeeked.remove(onSongSeeked);
		state.rateChanged.remove(onRateChanged);
		Settings.editorScrollSpeed.valueChanged.remove(onScrollSpeedChanged);
		Settings.editorScaleSpeedWithRate.valueChanged.remove(onScaleSpeedWithRateChanged);
	}

	function tryDrawSlice(index:Int)
	{
		if (index >= 0 && index < slices.length && slices[index] != null)
			slices[index].draw();
	}

	function generateWaveform()
	{
		sliceSize = Std.int(state.playfieldBG.height);

		sound = state.vocals;
		@:privateAccess {
			buffer = state.vocals._sound.__buffer;
			bytes = buffer.data.toBytes();
		}

		var t = 0;
		while (t < sound.length)
		{
			var endTime = Math.min(t + sliceSize, sound.length);
			var data = getWaveformData(buffer, bytes, t, endTime, sliceSize);
			var slice = new SongEditorWaveformSlice(state, data, sliceSize, t);
			slices.push(slice);
			t += sliceSize;
		}

		initializeSlicePool();
	}

	/*
		FROM PSYCH ENGINE
		Quaver uses some audio library that isn't available in Haxe so I took this from Psych Engine
	 */
	function getWaveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, ?steps:Float):Array<Array<Array<Float>>>
	{
		var array:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

		var khz = (buffer.sampleRate / 1000);
		var channels = buffer.channels;
		var index = Std.int(time * khz);
		var samples = ((endTime - time) * khz);
		var samplesPerRow = samples / steps;
		var samplesPerRowI = Std.int(samplesPerRow);
		var gotIndex:Int = 0;
		var lmin:Float = 0;
		var lmax:Float = 0;
		var rmin:Float = 0;
		var rmax:Float = 0;
		var rows:Float = 0;
		var simpleSample:Bool = true;
		var v1:Bool = false;

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > lmax)
						lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin)
						lmin = sample;
				}

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2)
						byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0)
					{
						if (sample > rmax)
							rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin)
							rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin);
				var lRMax:Float = lmax;

				var rRMin:Float = Math.abs(rmin);
				var rRMax:Float = rmax;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if (gotIndex > steps)
				break;
		}

		return array;
	}

	function initializeSlicePool()
	{
		slicePool = [];
		lastPooledSliceIndex = -1;
		for (i in 0...slices.length)
		{
			var slice = slices[i];
			if (!slice.sliceOnScreen())
				continue;

			slicePool.push(slice);
			lastPooledSliceIndex = i;
		}
	}

	function onSongSeeked(_, _)
	{
		initializeSlicePool();
	}

	function onRateChanged(_, _)
	{
		if (Settings.editorScaleSpeedWithRate.value)
			refreshSlices();
	}

	function onScrollSpeedChanged(_, _)
	{
		refreshSlices();
	}

	function onScaleSpeedWithRateChanged(_, _)
	{
		if (state.inst.pitch != 1)
			refreshSlices();
	}

	function refreshSlices()
	{
		for (slice in slices)
		{
			slice.updateSlice();
		}

		initializeSlicePool();
	}
}

class SongEditorWaveformSlice extends FlxSprite
{
	var state:SongEditorState;
	var sliceSize:Int;
	var sliceTime:Float;

	public function new(state:SongEditorState, waveformData:Array<Array<Array<Float>>>, sliceSize:Int, sliceTime:Float)
	{
		super();
		this.state = state;
		this.sliceSize = sliceSize;
		this.sliceTime = sliceTime;

		createSlice(waveformData);
		updateSlice();
	}

	override function destroy()
	{
		FlxG.bitmap.remove(graphic);
		graphic = null;
		super.destroy();
	}

	public function updateSlice()
	{
		scale.y = state.trackSpeed;
		updateHitbox();
		x = state.playfieldBG.x;
		y = state.hitPositionY - sliceTime * state.trackSpeed - height;
	}

	public function sliceOnScreen()
	{
		return sliceTime * state.trackSpeed >= state.trackPositionY - state.playfieldBG.height
			&& sliceTime * state.trackSpeed <= state.trackPositionY + state.playfieldBG.height;
	}

	function createSlice(data:Array<Array<Array<Float>>>)
	{
		makeGraphic(Std.int(state.playfieldBG.width), sliceSize, FlxColor.TRANSPARENT, true, 'waveform');

		var gSize:Int = Std.int(width);
		var hSize:Int = Std.int(gSize / 2);
		var lmin:Float = 0;
		var lmax:Float = 0;
		var rmin:Float = 0;
		var rmax:Float = 0;
		var size:Float = 1;
		var leftLength:Int = (data[0][0].length > data[0][1].length ? data[0][0].length : data[0][1].length);
		var rightLength:Int = (data[1][0].length > data[1][1].length ? data[1][0].length : data[1][1].length);
		var length:Int = leftLength > rightLength ? leftLength : rightLength;
		var index:Int;

		pixels.lock();
		for (i in 0...length)
		{
			index = i;

			lmin = FlxMath.bound(((index < data[0][0].length && index >= 0) ? data[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = FlxMath.bound(((index < data[0][1].length && index >= 0) ? data[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			rmin = FlxMath.bound(((index < data[1][0].length && index >= 0) ? data[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = FlxMath.bound(((index < data[1][1].length && index >= 0) ? data[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}
		pixels.unlock();

		flipY = true; // im too lazy to figure out how to flip it in the actual bitmap
	}
}
