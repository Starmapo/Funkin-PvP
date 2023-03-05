package data.song;

import flixel.math.FlxMath;

class DifficultyProcessor
{
	static var laneToFinger:Map<Int, FingerState> = [0 => MIDDLE, 1 => INDEX, 2 => INDEX, 3 => MIDDLE];
	static var laneToHand:Map<Int, Hand> = [0 => LEFT, 1 => LEFT, 2 => RIGHT, 3 => RIGHT];

	public var overallDifficulty:Float = 0;
	public var averageNoteDensity:Float = 0;
	public var strainSolverData:Array<StrainSolverData> = [];

	var song:Song;
	var rollInaccuracyConfidence:Int = 0;
	var vibroInaccuracyConfidence:Int = 0;

	public function new(song:Song, mods:Modifiers)
	{
		this.song = song;

		if (song == null || song.notes.length < 2)
			return;

		calculateDifficulty(mods);
	}

	function calculateDifficulty(mods:Modifiers)
	{
		var rate = mods.playbackRate;
		overallDifficulty = computeForOverallDifficulty(rate);
	}

	function computeForOverallDifficulty(rate:Float = 1)
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
		averageNoteDensity = 1000 * song.notes.length / (song.length * (-0.5 * rate + 1.5));
	}

	function computeBaseStrainStates(rate:Float = 1)
	{
		for (i in 0...song.notes.length)
		{
			var curNote = new StrainSolverNote(song.notes[i]);
			var curStrainData = new StrainSolverData(curNote, rate);
			curNote.fingerState = laneToFinger[song.notes[i].lane];
			curStrainData.hand = laneToHand[song.notes[i].lane];
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
							strainSolverData[i].notes.push(k);
					}
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
					}
					else if (actionSameState)
					{
						curNote.fingerAction = SIMPLE_JACK;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 40, 320, 68, 1.17);
					}
					else if (actionJackFound)
					{
						curNote.fingerAction = TECHNICAL_JACK;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 40, 330, 70, 1.14);
					}
					else
					{
						curNote.fingerAction = BRACKET;
						curNote.actionStrainCoefficient = getCoefficientValue(actionDuration, 30, 230, 56, 1.13);
					}
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
			}
		}
	}

	function calculateOverallDifficulty()
	{
		var calculatedDiff:Float = 0;

		for (data in strainSolverData)
			data.calculateStrainValue();

		return calculatedDiff;
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

class StrainSolverNote
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
}

class StrainSolverData
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

	function get_handChord()
	{
		return notes.length > 1;
	}
}

@:enum abstract FingerState(Int) from Int to Int
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
