package util;

import thx.semver.Version;
import util.github.GitHub;
import util.github.GitHubRelease;

class UpdateUtil
{
	public static final repoOwner:String = "Starmapo";
	public static final repoName:String = "Funkin-PvP";
	
	public static function checkForUpdates():UpdateCheckCallback
	{
		var curTag:Version = CoolUtil.getVersion();
		
		var error = false;
		
		var releases = GitHub.getReleases(repoOwner, repoName, function(e)
		{
			error = true;
		});
		
		if (error)
			return {success: false, newUpdate: false};
			
		var lastRelease = releases[0];
		if (lastRelease == null || curTag >= (lastRelease.tag_name : Version))
			return {success: true, newUpdate: false};
			
		return {
			success: true,
			newUpdate: true,
			currentVersionTag: curTag,
			release: lastRelease
		}
	}
}

typedef UpdateCheckCallback =
{
	var success:Bool;
	var newUpdate:Bool;
	var ?currentVersionTag:String;
	var ?release:GitHubRelease;
}
