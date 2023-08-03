package backend.github;

typedef GitHubRelease =
{
	/**
	 * Link to the release on GitHub.
	 */
	var html_url:String;

    /**
        The name of the tag of the release.
    **/
	var tag_name:String;
	
	/**
	 * Body/Markdown text of the release.
	 */
	var body:String;
}
