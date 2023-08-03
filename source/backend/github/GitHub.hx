package backend.github;

import haxe.Exception;
import haxe.Http;
import haxe.Json;

class GitHub
{
	/**
	 * Gets all the releases from a specific GitHub repository using the GitHub API.
	 * @param user 
	 * @param repository 
	 * @return Releases
	 */
	public static function getReleases(user:String, repository:String, ?onError:Exception->Void):Array<GitHubRelease>
	{
		try
		{
			var url = 'https://api.github.com/repos/${user}/${repository}/releases';
			
			var data = Json.parse(_requestOnGitHubServers(url));
			if (!(data is Array))
				throw _parseGitHubException(data);
				
			return data;
		}
		catch (e)
		{
			if (onError != null)
				onError(e);
		}
		return [];
	}
	
	static function _requestOnGitHubServers(url:String):String
	{
		var h = new Http(url);
		h.setHeader("User-Agent", "request");
		var r = null;
		h.onData = function(d)
		{
			r = d;
		}
		h.onError = function(e)
		{
			throw e;
		}
		h.request(false);
		return r;
	}
	
	static function _parseGitHubException(obj:Dynamic):GitHubException
	{
		var msg:String = "(No message)";
		var url:String = "(No API url)";
		if (Reflect.hasField(obj, "message"))
			msg = Reflect.field(obj, "message");
		if (Reflect.hasField(obj, "documentation_url"))
			url = Reflect.field(obj, "documentation_url");
		return new GitHubException(msg, url);
	}
}
