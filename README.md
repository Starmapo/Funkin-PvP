# Friday Night Funkin' PvP

The open source code of Friday Night Funkin' PvP.

**As of the moment, version 0.1 is still in development and nothing is promised to be kept the same until release, so use this at your own risk.**

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
