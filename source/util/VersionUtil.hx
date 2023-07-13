package util;

import thx.semver.Version;
import thx.semver.VersionRule;

class VersionUtil
{
	public static final DEFAULT_VERSION_RULE:VersionRule = "*.*.*";
	
	public static inline function match(version:Version, rule:VersionRule):Bool
	{
		return stripPre(version).satisfies(rule);
	}
	
	public static inline function stripPre(version:Version):Version
	{
		return '${version.major}.${version.minor}.${version.patch}';
	}

	public static inline function combineRulesAnd(ruleA:VersionRule, ruleB:VersionRule):VersionRule
	{
		return AndRule(ruleA, ruleB);
	}
}
