package states.options;

enum PageName
{
	Options;
	Players;
	Player(player:Int);
	Controls(player:Int);
	NoteSkin(player:Int);
	JudgementSkin(player:Int);
	SplashSkin(player:Int);
	Video;
	Audio;
	Gameplay;
	Miscellaneous;
}
