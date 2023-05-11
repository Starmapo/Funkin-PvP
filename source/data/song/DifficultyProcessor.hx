package data.song;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;

/**
	Literally everything here comes from Quaver, huge thanks to the Quaver team.
	And no, I don't understand most of the code that's here. If something isn't right I probably won't notice lol.
**/
class DifficultyProcessor implements IFlxDestroyable
{
	public static function getDifficultyName(difficulty:Float)
	{
		if (difficulty < 1)
			return 'Beginner';
		if (difficulty < 2.5)
			return 'Easy';
		if (difficulty < 10)
			return 'Normal';
		if (difficulty < 20)
			return 'Hard';
		if (difficulty < 30)
			return 'Insane';
		if (difficulty < 40)
			return 'Expert';
		if (difficulty < 50)
			return 'Expert+';

		return '???';
	}

	public static function getDifficultyColor(difficulty:Float)
	{
		if (difficulty < 1)
			return 0xFFD1FFFA;
		if (difficulty < 2.5)
			return 0xFF5EFF75;
		if (difficulty < 10)
			return 0xFF5EC4FF;
		if (difficulty < 20)
			return 0xFFF5B25B;
		if (difficulty < 30)
			return 0xFFF9645D;
		if (difficulty < 40)
			return 0xFFD761EB;
		if (difficulty < 50)
			return 0xFF7B61EB;

		return 0xFFB7B7B7;
	}

	static var laneToFinger:Map<Int, FingerState> = [0 => MIDDLE, 1 => INDEX, 2 => INDEX, 3 => MIDDLE];
	static var laneToHand:Map<Int, Hand> = [0 => LEFT, 1 => LEFT, 2 => RIGHT, 3 => RIGHT];

	public var overallDifficulty:Float = 0;
	public var averageNoteDensity:Float = 0;
	public var strainSolverData:Array<StrainSolverData> = [];

	var song:Song;
	var rightSide:Bool = false;
	var notes:Array<NoteInfo> = [];
	var rollInaccuracyConfidence:Int = 0;
	var vibroInaccuracyConfidence:Int = 0;

	public function new(song:Song, rightSide:Bool = false, rate:Float = 1)
	{
		this.song = song;
		this.rightSide = rightSide;

		if (song == null)
			return;

		for (note in song.notes)
		{
			if ((!rightSide && note.lane < 4) || (rightSide && note.lane > 3))
				notes.push(new NoteInfo({
					startTime: note.startTime,
					lane: note.playerLane,
					endTime: note.endTime,
					type: note.type,
					params: note.params.join(',')
				}));
		}

		if (notes.length < 2)
			return;

		calculateDifficulty(rate);
	}

	public function destroy()
	{
		strainSolverData = FlxDestroyUtil.destroyArray(strainSolverData);
		song = null;
		notes = FlxDestroyUtil.destroyArray(notes);
	}

	function calculateDifficulty(rate:Float)
	{
		overallDifficulty = computeForOverallDifficulty(rate);
	}

	function computeForOverallDifficulty(rate:Float)
	{
		computeNoteDensityData(rate);
		computeBaseStrainStates(rate);
		computeForChords();
		computeForFingerActions();
		computeForRollManipulation();
		computeForJackManipulation();
		computeForLnMultiplier();
		return calculateOverallDifficulty();
	}

	function computeNoteDensityData(rate:Float = 1)
	{
		averageNoteDensity = 1000 * notes.length / (song.length * (-0.5 * rate + 1.5));
	}

	function computeBaseStrainStates(rate:Float = 1)
	{
		for (i in 0...notes.length)
		{
			var curNote = new StrainSolverNote(notes[i]);
			var curStrainData = new StrainSolverData(curNote, rate);
			curNote.fingerState = laneToFinger[notes[i].lane];
			curStrainData.hand = laneToHand[notes[i].lane];
			strainSolverData.push(curStrainData);
		}
	}

	function computeForChords()
	{
		var chordClumpToleranceMs = 8;

		for (i in 0...strainSolverData.length - 1)
		{
			for (j in i + 1...strainSolverData.length)
			{
				if (strainSolverData[j] == null)
					continue;

				var msDiff = strainSolverData[j].startTime - strainSolverData[i].startTime;
				if (msDiff > chordClumpToleranceMs)
					break;

				if (Math.abs(msDiff) <= chordClumpToleranceMs && strainSolverData[i].hand == strainSolverData[j].hand)
				{
					for (k in strainSolverData[j].notes)
					{
						var sameStateFound = false;
						for (l in strainSolverData[i].notes)
						{
							if (l.fingerState == k.fingerState)
							{
								sameStateFound = true;
								break;
							}
						}

						if (!sameStateFound)
						{
							strainSolverData[i].notes.push(k);
							// trace('Found chord: ${strainSolverData[i].startTime}, ${k.note.startTime}, ${k.note.lane}, ${strainSolverData[i].hand}');
						}
					}

					strainSolverData.remove(strainSolverData[j]);
				}
			}
		}

		for (i in 0...strainSolverData.length)
		{
			strainSolverData[i].solveFingerState();
		}
	}

	function computeForFingerActions()
	{
		for (i in 0...strainSolverData.length - 1)
		{
			var curNote = strainSolverData[i];
			for (j in i + 1...strainSolverData.length)
			{
				var nextNote = strainSolverData[j];
				if (curNote.hand == nextNote.hand && nextNote.startTime > curNote.startTime)
				{
					var actionJackFound = (curNote.fingerState & nextNote.fingerState) != 0;
					var actionChordFound = curNote.handChord || nextNote.handChord;
					var actionSameState = curNote.fingerState == nextNote.fingerState;
					var actionDuration = nextNote.startTime - curNote.startTime;
					curNote.nextStrainSolverDataOnCurrentHand = nextNote;
					curNote.fingerActionDurationMs = actionDuration;

					if (!actionChordFound && !actionSameState)
					{
						curNote.fingerAction = ROLL;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 30, 230, 55, 1.13);
						// trace('Found roll action: ${curNote.startTime}, ${nextNote.startTime}, ${curNote.fingerState}, ${nextNote.fingerState}, ${curNote.actionStrainCoefficient}');
					}
					else if (actionSameState)
					{
						curNote.fingerAction = SIMPLE_JACK;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 40, 320, 68, 1.17);
						// trace('Found simple jack action: ${curNote.startTime}, ${nextNote.startTime}, ${curNote.fingerState}, ${curNote.actionStrainCoefficient}');
					}
					else if (actionJackFound)
					{
						curNote.fingerAction = TECHNICAL_JACK;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 40, 330, 70, 1.14);
						// trace('Found technical jack action: ${curNote.startTime}, ${nextNote.startTime}, ${curNote.fingerState}, ${nextNote.fingerState}, ${curNote.actionStrainCoefficient}');
					}
					else
					{
						curNote.fingerAction = BRACKET;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 30, 230, 56, 1.13);
						// trace('Found bracket action: ${curNote.startTime}, ${nextNote.startTime}, ${curNote.fingerState}, ${nextNote.fingerState}, ${curNote.actionStrainCoefficient}');
					}

					break;
				}
			}
		}
	}

	function computeForRollManipulation()
	{
		var rollMaxLength = 14;

		var manipulationIndex = 0;
		for (data in strainSolverData)
		{
			var manipulationFound = false;

			if (data.nextStrainSolverDataOnCurrentHand != null
				&& data.nextStrainSolverDataOnCurrentHand.nextStrainSolverDataOnCurrentHand != null)
			{
				var middle = data.nextStrainSolverDataOnCurrentHand;
				var last = middle.nextStrainSolverDataOnCurrentHand;
				if (data.fingerAction == ROLL && middle.fingerAction == ROLL)
				{
					if (data.fingerState == last.fingerState)
					{
						var durationRatio = Math.max(data.fingerActionDurationMs / middle.fingerActionDurationMs,
							middle.fingerActionDurationMs / data.fingerActionDurationMs);
						if (durationRatio >= 2)
						{
							var durationMultiplier = 1 / (1 + (durationRatio - 1) * 0.25);

							var manipulationFoundRatio = 1 - manipulationIndex / rollMaxLength * (1 - 0.6);
							data.rollManipulationStrainMultiplier = durationMultiplier * manipulationFoundRatio;

							manipulationFound = true;
							rollInaccuracyConfidence++;

							// trace('Roll manipulation found: ${data.startTime}, ${data.fingerState}, ${data.rollManipulationStrainMultiplier}');

							if (manipulationIndex < rollMaxLength)
								manipulationIndex++;
						}
					}
				}
			}

			if (!manipulationFound && manipulationIndex > 0)
				manipulationIndex--;
		}
	}

	function computeForJackManipulation()
	{
		var vibroActionToleranceMs = 88.2;
		var vibroMaxLength = 6;

		var longJackSize = 0;
		for (data in strainSolverData)
		{
			var manipulationFound = false;

			if (data.nextStrainSolverDataOnCurrentHand != null)
			{
				var next = data.nextStrainSolverDataOnCurrentHand;

				if (data.fingerAction == SIMPLE_JACK && next.fingerAction == SIMPLE_JACK)
				{
					var durationValue = FlxMath.bound((88.2 + vibroActionToleranceMs - data.fingerActionDurationMs) / vibroActionToleranceMs, 0, 1);

					var durationMultiplier = 1 - durationValue * (1 - 0.75);
					var manipulationFoundRatio = 1 - longJackSize / vibroMaxLength * (1 - 0.3);
					data.rollManipulationStrainMultiplier = durationMultiplier * manipulationFoundRatio;

					manipulationFound = true;
					vibroInaccuracyConfidence++;

					// trace('Jack manipulation found: ${data.startTime}, ${data.fingerState}, ${data.rollManipulationStrainMultiplier}');

					if (longJackSize < vibroMaxLength)
						longJackSize++;
				}
			}

			if (!manipulationFound)
				longJackSize = 0;
		}
	}

	function computeForLnMultiplier()
	{
		var lnLayerToleranceMs = 60;
		var lnEndTresholdMs = 42;

		for (data in strainSolverData)
		{
			if (data.endTime > data.startTime)
			{
				var durationValue = 1 - FlxMath.bound((93.7 + lnLayerToleranceMs - (data.endTime - data.startTime)) / lnLayerToleranceMs, 0, 1);
				var baseMultiplier = 1 + durationValue * 0.6;

				for (k in data.notes)
					k.lnStrainMultiplier = baseMultiplier;

				var next = data.nextStrainSolverDataOnCurrentHand;
				if (next != null && next.startTime < data.endTime - lnEndTresholdMs && next.startTime >= data.startTime + lnEndTresholdMs)
				{
					if (next.endTime > data.endTime + lnEndTresholdMs)
					{
						for (k in data.notes)
						{
							k.lnLayerType = OUTSIDE_RELEASE;
							k.lnStrainMultiplier *= 1;
						}
					}
					else if (next.endTime > 0)
					{
						for (k in data.notes)
						{
							k.lnLayerType = INSIDE_RELEASE;
							k.lnStrainMultiplier *= 1.3;
						}
					}
					else
					{
						for (k in data.notes)
						{
							k.lnLayerType = INSIDE_TAP;
							k.lnStrainMultiplier *= 1.05;
						}
					}
				}

				// trace('Long note multiplier: ${data.startTime}, ${data.notes[0].lnStrainMultiplier}, ${data.notes[0].lnLayerType}');
			}
		}
	}

	function calculateOverallDifficulty():Float
	{
		var calculatedDiff:Float = 0;

		for (data in strainSolverData)
			data.calculateStrainValue();

		var filteredStrains = strainSolverData.filter(function(s) return s.hand == LEFT || s.hand == RIGHT);
		for (strain in filteredStrains)
		{
			calculatedDiff += strain.totalStrainValue;
		}
		calculatedDiff /= filteredStrains.length;

		// trace('Average strain value: $calculatedDiff');

		var bins:Array<Float> = [];
		var binSize = 1000;

		var mapStart = Math.POSITIVE_INFINITY;
		var mapEnd = Math.NEGATIVE_INFINITY;
		for (strain in strainSolverData)
		{
			if (strain.startTime < mapStart)
				mapStart = strain.startTime;

			var endTime = Math.max(strain.startTime, strain.endTime);
			if (endTime > mapEnd)
				mapEnd = endTime;
		}

		var i = mapStart;
		while (i < mapEnd)
		{
			var valuesInBin = strainSolverData.filter(function(s) return s.startTime >= i && s.startTime < i + binSize);
			var averageRating:Float = 0;
			if (valuesInBin.length > 0)
			{
				for (s in valuesInBin)
				{
					averageRating += s.totalStrainValue;
				}
				averageRating /= valuesInBin.length;
			}
			bins.push(averageRating);

			i += binSize;
		}

		if (bins.filter(function(strain) return strain > 0).length == 0)
			return 0;

		var cutoffPos = Math.floor(bins.length * 0.4);
		var top40 = bins.copy();
		top40.sort(function(a, b) return FlxSort.byValues(FlxSort.DESCENDING, a, b));
		top40 = top40.slice(0, cutoffPos);
		var easyRatingCutoff:Float = 0;
		if (top40.length > 0)
		{
			for (s in top40)
			{
				easyRatingCutoff += s;
			}
			easyRatingCutoff /= top40.length;
		}

		var continuityStrains = bins.filter(function(strain) return strain > 0);
		var continuity:Float = 0;
		for (strain in continuityStrains)
		{
			continuity += Math.sqrt(strain / easyRatingCutoff);
		}
		continuity /= continuityStrains.length;

		// trace('Continuity: $continuity');

		var maxContinuity = 1;
		var avgContinuity = 0.85;
		var minContinuity = 0.6;
		var maxAdjustment = 1.05;
		var avgAdjustment = 1;
		var minAdjustment = 0.9;

		var continuityAdjustment:Float = 0;

		if (continuity > avgContinuity)
		{
			var continuityFactor = 1 - (continuity - avgContinuity) / (maxContinuity - avgContinuity);
			continuityAdjustment = FlxMath.bound(continuityFactor * (avgAdjustment - minAdjustment) + minAdjustment, minAdjustment, avgAdjustment);
		}
		else
		{
			var continuityFactor = 1 - (continuity - minContinuity) / (avgContinuity - minContinuity);
			continuityAdjustment = FlxMath.bound(continuityFactor * (maxAdjustment - avgAdjustment) + avgAdjustment, avgAdjustment, maxAdjustment);
		}

		// trace('Continuity adjustment: $continuityAdjustment');

		calculatedDiff *= continuityAdjustment;

		var trueDrainTime = bins.length * continuity * binSize;
		var shortMapAdjustment = FlxMath.bound(0.25 * Math.sqrt(trueDrainTime / 60000) + 0.75, 0.75, 1);

		// trace('Short map adjustment: $shortMapAdjustment');

		calculatedDiff *= shortMapAdjustment;

		return FlxMath.roundDecimal(calculatedDiff, 2);
	}

	function getCoefficientValue(duration:Float, xMin:Float, xMax:Float, strainMax:Float, exp:Float)
	{
		var lowestDifficulty = 1;
		var densityMultiplier = 0.266;
		var densityDifficultyMin = 0.4;

		var ratio = Math.max(0, 1 - (duration - xMin) / (xMax - xMin));

		if (ratio == 0 && averageNoteDensity < 4)
		{
			if (averageNoteDensity < 1)
				return densityDifficultyMin;

			return averageNoteDensity * densityMultiplier + 0.134;
		}

		return lowestDifficulty + (strainMax - lowestDifficulty) * Math.pow(ratio, exp);
	}
}

class StrainSolverNote implements IFlxDestroyable
{
	public var note:NoteInfo;
	public var fingerState:FingerState = NONE;
	public var lnStrainMultiplier:Float = 1;
	public var lnLayerType:LnLayerType = NONE;
	public var strainValue:Float = 0;

	public function new(note:NoteInfo)
	{
		this.note = note;
	}

	public function destroy()
	{
		note = null;
	}
}

class StrainSolverData implements IFlxDestroyable
{
	public var notes:Array<StrainSolverNote> = [];
	public var startTime:Float = 0;
	public var endTime:Float = 0;
	public var hand:Hand;
	public var fingerState:FingerState = NONE;
	public var handChord(get, never):Bool;
	public var nextStrainSolverDataOnCurrentHand:StrainSolverData;
	public var fingerAction:FingerAction = NONE;
	public var fingerActionDurationMs:Float = 0;
	public var actionStrainCoefficient:Float = 1;
	public var rollManipulationStrainMultiplier:Float = 1;
	public var totalStrainValue:Float = 0;

	public function new(strainNote:StrainSolverNote, rate:Float = 1)
	{
		startTime = strainNote.note.startTime / rate;
		endTime = strainNote.note.endTime / rate;
		notes.push(strainNote);
	}

	public function solveFingerState()
	{
		for (note in notes)
		{
			fingerState |= note.fingerState;
		}
	}

	public function calculateStrainValue()
	{
		for (note in notes)
		{
			note.strainValue = actionStrainCoefficient * rollManipulationStrainMultiplier * note.lnStrainMultiplier;
			totalStrainValue += note.strainValue;
		}

		totalStrainValue /= notes.length;
	}

	public function destroy()
	{
		notes = FlxDestroyUtil.destroyArray(notes);
		nextStrainSolverDataOnCurrentHand = null;
	}

	function get_handChord()
	{
		return notes.length > 1;
	}
}

enum abstract FingerState(Int) from Int to Int
{
	var NONE = 0;
	var INDEX = 1 << 0;
	var MIDDLE = 1 << 1;
	var RING = 1 << 2;
	var PINKIE = 1 << 3;
	var THUMB = 1 << 4;
}

enum FingerAction
{
	NONE;
	SIMPLE_JACK;
	TECHNICAL_JACK;
	ROLL;
	BRACKET;
}

enum Hand
{
	LEFT;
	RIGHT;
}

enum LnLayerType
{
	NONE;
	INSIDE_RELEASE;
	OUTSIDE_RELEASE;
	INSIDE_TAP;
}
