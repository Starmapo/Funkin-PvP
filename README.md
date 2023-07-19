# Friday Night Funkin' PvP

The open source code of Friday Night Funkin' PvP.

## Compiling

You should already have [Haxe](https://haxe.org/download/) installed.

1. Install the [Haxe module manager](https://lib.haxe.org/p/hmm/) if you haven't already, and use it to install all the required dependencies (`hmm install`). Some dependencies are from GitHub and some others are modified versions by me, so it's important that you do this.
2. If this is your first time using Lime, run `haxelib run lime setup` to be able to use the `lime` command, then run the setup for your platform (e.g. `lime setup windows`).
3. Rebuild the Lime and systools binaries for your platform (e.g. `lime rebuild windows` and `lime rebuild systools windows`). This may take a while.
4. Use `lime test` to test the game (e.g. `lime test windows -debug`), or if you're using Visual Studio Code, select your Lime Target Configuration and use the "Run and Debug" options. This also may take a while.
