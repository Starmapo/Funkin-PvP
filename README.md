# Friday Night Funkin' PvP

The open source code of Friday Night Funkin' PvP, a WIP fangame.

**As of the moment, version 0.1 is still in development and nothing is promised to be kept the same until release, so use this at your own risk.**

## Fangame? Is this not a mod?

Although it uses some code from other FNF projects, this game was built from the ground up. Most things are completely different from the base game or other engines, including the gameplay code and the song structures.

## Modding

The game heavily relies on modpacks (even the base Friday Night Funkin' content is in its own mod), meaning you can easily softcode your own songs, characters, etc.

Modding documentation is yet to be done, as the game is unreleased and still being worked on. However, you can take a look at the official mods for examples on how to make one, as long as you have some coding experience already.

## Credits

- [Starmapo](https://starmapo.carrd.co/) - Creator and programmer
- [ThatAzazelFire](https://linktr.ee/thatazazelfire) - Lending me some of his character sprites

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
