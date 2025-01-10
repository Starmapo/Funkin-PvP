# Friday Night Funkin' PvP

The unfinished source code of Friday Night Funkin' PvP, a cancelled fangame which revolves around a local multiplayer mode.

## Why is it cancelled?

To put it shortly, I began to lose motivation to work on the game, and I had doubts that people would actually be interested in it. I hadn't posted anything publicly about it (outside of a preview on YouTube, which didn't get a lot of attention anyways), so it was easier to make the decision to cancel it.

I don't want all the months of code to go to waste, so I've released it publicly here. If anyone wants to continue the game, you have my permission, though be aware that the code is rather messy and I was planning on revamping it before I decided to cancel it. The controls page was left unfinished, but you can find the original working version by going through the commit history.

## Fangame? Is this not a mod?

Although it uses some code from other FNF projects, this game was built from the ground up. Most things are completely different from the base game or other engines, including the gameplay code and the song structures.

## Modding

The game heavily relies on modpacks (even the base Friday Night Funkin' content is in its own mod), meaning you can softcode your own songs, characters, etc.

There is no modding documentation, as it was cancelled before it could be written. However, you can take a look at the official mods for an idea of how to make one, as long as you have some coding experience already.

## Credits

- [Starmapo](https://starmapo.carrd.co/) - Creator and programmer

### Assets

- [Friday Night Funkin'](https://github.com/FunkinCrew/Funkin)
- [PhantomMuff font](https://gamebanana.com/tools/7763)
- VCR OSD Mono font
- Pixel Arial 11 font
- [YoshiCrafter Engine](https://github.com/FNF-CNE-Devs/YoshiCrafterEngine) - Color picker assets
- [Quaver Team](https://github.com/Quaver/Quaver) - Song editor hitsound and metronome sounds

### Base game and engines

- [Friday Night Funkin'](https://github.com/FunkinCrew/Funkin)
- [Andromeda Engine](https://github.com/nebulazorua/andromeda-engine-legacy)
- [Codename Engine](https://github.com/FNF-CNE-Devs/CodenameEngine)
- [Forever Engine](https://github.com/SomeKitten/Forever-Engine)
- [FPS Plus](https://github.com/ThatRozebudDude/FPS-Plus-Public)
- [Kade Engine](https://github.com/Kade-github/Kade-Engine)
- [Leather Engine](https://github.com/Leather128/LeatherEngine)
- [Mic'd Up](https://github.com/Verwex/Funkin-Mic-d-Up-SC)
- [Modding Plus](https://github.com/FunkinModdingPlus/ModdingPlus)
- [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine)
- [YoshiCrafter Engine](https://github.com/FNF-CNE-Devs/YoshiCrafterEngine)

### Special Thanks

- [Quaver Team](https://github.com/Quaver/Quaver) - Gameplay code is based on theirs

More credits can be found in their respective menu in-game.

## Building from source

### Supported Platforms

- Windows

### Probably supported, but needs testing

- macOS
- Linux

### Prerequisites

1. Install [Haxe](https://haxe.org/download/). Versions from 4.3.1 to the last 4.x.x release should work.
2. Install the [Haxe module manager](https://lib.haxe.org/p/hmm/), and use it to locally install all the required dependencies (`hmm install` inside the project directory).
3. Run `haxelib run lime setup` to be able to use the `lime` shortcut, then run the setup for your platform (e.g. `lime setup windows`).
4. Rebuild the Lime and systools binaries for your platform (e.g. `lime rebuild windows` and `lime rebuild systools windows`). This may take a while.

### Compiling

Use `lime test` to test the game (e.g. `lime test windows -debug`), or if you're using Visual Studio Code, select your Lime Target Configuration and use `Run and Debug`` with the "Build + Debug" configuration. This also may take a while.

## License

This game is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License. More information can be found in the LICENSE.txt file.

Licenses for Friday Night Funkin' and OpenFL are contained in separate files.

Licenses for content in mods can be found in their folder.
