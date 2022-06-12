<!-- REFERENCE: https://shields.io/ -->

[![GitHub version](https://badge.fury.io/gh/CarlosLeyvaAyala%2FMax-Sick-Gains.svg)](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains) ![Project-Status-Active](https://img.shields.io/badge/status-active-green.svg) [![powered-by-Skyrim-Platform](https://img.shields.io/badge/Powered%20by-Skyrim%20Platform-2c3e69.svg)](https://www.nexusmods.com/skyrimspecialedition/mods/54909) [![made-with-Lua](https://img.shields.io/badge/Made%20with-Lua-1f425f.svg)](https://www.lua.org/) [![made-with-Markdown](https://img.shields.io/badge/Made%20with-Markdown-1f425f.svg)](http://commonmark.org)

<!-- [![made-with-python](https://img.shields.io/badge/Made%20with-Python-1f425f.svg)](https://www.python.org/) [![made-with-lazarus](https://img.shields.io/badge/Made%20with-Lazarus-1f425f.svg)](https://www.lazarus-ide.org/) -->

# About Max Sick Gains

Skyrim SE mod to change Player Character (PC) body shape by training. \
Many different shapes are possible by changing Bodyslide shapes at different fitness stages.

NPCs body shapes can be varied as well.

This mod's philosophy is to **make people to look like they should according to their profession**.\
Warriors should be muscular and ripped, mages should be thin... or even fat and flabby.

# Features

- Change fitness levels (stages) by training.
- Player can have a different body shape (Bodyslide preset) and/or muscle definition at each stage.
- Unlimited fitness levels for PC.
- Unlimited body types for NPCs.
- Works for men and women alike.
- All vanilla races supported.
- Custom race support is possible with almost no hassle.
- Optional use of normal maps to make characters ripped/fat/plain according to their body type (this means: no fat bodies with ripped abs).
- Total control on how each NPC should look like. No randomness for the sake of randomness.
- **Training is gained based on what you do**, not what skills you level up.\
  Casting magic won't have impact on your appearance per se, but adventuring will.\
  Swimming, sprinting, jumping and fighting using your body all contribute to your overall appearance.

It's as simple to use as it can be.

- Powerful and flexible.
- No patches.
- No need to delve into arcane configuration files. This mod does that for you.

# Features for modders

Want your mod to take into account how your PC looks like? It's a breeze to integrate it with mine.

- An easy to use API for quickly integration.
- Communication with external mods via mod events.
- Functions to save data related to this mod.

# Requirements

As a player, you need these mods and all their requirements to make it work.

- Skyrim SE
- [Skyrim Platform][sp]
- [Bodyslide][]
- [iWant Widgets][]
- [JContainers SE][jcontainers-se]
- [MCM Helper][]
- NiOverride ([Racemenu][])
- [Papyrus Util][]
- [powerofthree's Tweaks][po3tweaks] (enable _"Cast No Death Dispel Spells on Load"_)
- [SPID][] 5.0.3 on SE (5.2.0 doesn't seem to work). 5.2+ seems to work alright on AE.
- Some Bodyslide presets

## The AE aftermath

### Special Edition

Even if you use the [downgrade patch][downgrade], you need to completely restore SE by following [this guide][hugo].\
For some reason, that AE prompt overlay on the main menu seems to mess with some mods.

Note to MO users: you don't need to replace/delete new files; it's just a matter of adding the old SE files to a new folder, then activate it.\
CC files won't trigger the AE overlay, by the way.

If you don't follow these steps **this mod won't work on NPCs**.

### Annoying Edition

This mod seems to be stable, but now we get some weird errors that never happened on SE, like Slideshow on Testing Mode not working because sometimes the game refuses to update morphs unless you equip an armor, and things like those.

Not much can be done by me about these kind of things, honestly.

## Integrations

Not required, but this mod will detect them and act accordingly.

- [Sexlab framework][sexlab-framework]
<!-- - [OStim][] -->

# Build dependencies

This only concerns you if you want to develop this project. \
You'll need requirements for players (including integrations) plus:

<!-- - Lua -->

- [dmlib][]

## Visual Studio Code

**Maybe** not required _per se_, but this project was made on it and it uses many tools available for it.

- [Visual Studio Code][visual-studio-code]
- [Papyrus for Visual Studio Code][vscode-papyrus]
- [Fira code][fira-code]
- [Markdown Preview Enhanced][markdown-preview] (well... this is actually required to build all docs in this project `¯\_(ツ)_/¯`)
- [Hightlight][]
- [Fold Plus][fold-plus]
- [Separators] <!-- - [Lua (language server)][lua-language-server] -->
- [Numbered Bookmarks][numbered-bookmarks]
- [Clipboard Manager][clipboard-manager]
- [Tokyo Night][tokyo-night]

<!-- ## QOL tools

### For Lua

- [ZeroBrane Studio][zerobrane-studio]
- [Serpent][] Lua serializer and pretty printer
- [Clipboard][] -->

# Other resources

- [Markdown styleguide][markdown-styleguide]

<!-- <details>
  <summary>Winter</summary>
  <p>Sparkling and frozen!</p>
</details> -->

<!--
https://badge.fury.io/for/gh/CarlosLeyvaAyala/Max-Sick-Gains?type=svg

To ensure prompt updates to your badge, please set up a webhook for your GitHub repo that points to:

https://badge.fury.io/hooks/github

-->

<!-- -------------------------------------------- -->

[bodyslide]: https://www.nexusmods.com/skyrimspecialedition/mods/201
[clipboard-manager]: https://marketplace.visualstudio.com/items?itemname=edgardmessias.clipboard-manager
[clipboard]: http://luaforge.net/projects/jaslatrix/
[dmlib]: https://github.com/carlosleyvaayala/dm-skyrimse-library.git
[downgrade]: https://www.nexusmods.com/skyrimspecialedition/mods/57618
[fira-code]: https://github.com/tonsky/firacode
[fold-plus]: https://marketplace.visualstudio.com/items?itemname=dakara.dakara-foldplus
[hightlight]: https://marketplace.visualstudio.com/items?itemname=fabiospampinato.vscode-highlight
[hugo]: https://www.nexusmods.com/skyrimspecialedition/images/131378
[iwant widgets]: https://www.nexusmods.com/skyrimspecialedition/mods/36457
[jcontainers-se]: https://www.nexusmods.com/skyrimspecialedition/mods/16495
[lazarus docs]: _Tools/TexRename
[lua-language-server]: https://marketplace.visualstudio.com/items?itemname=sumneko.lua
[markdown-preview]: https://marketplace.visualstudio.com/items?itemname=shd101wyy.markdown-preview-enhanced
[markdown-styleguide]: https://arcticicestudio.github.io/styleguide-markdown/
[mcm helper]: https://www.nexusmods.com/skyrimspecialedition/mods/53000
[numbered-bookmarks]: https://marketplace.visualstudio.com/items?itemname=alefragnani.numbered-bookmarks
[ostim]: https://www.nexusmods.com/skyrimspecialedition/mods/40725
[papyrus util]: https://www.nexusmods.com/skyrimspecialedition/mods/13048
[po3tweaks]: https://www.nexusmods.com/skyrimspecialedition/mods/51073
[python docs]: _Tools/MainPython
[racemenu]: https://www.nexusmods.com/skyrimspecialedition/mods/19080
[separators]: https://marketplace.visualstudio.com/items?itemName=alefragnani.separators
[serpent]: http://notebook.kulchenko.com/programming/serpent-lua-serializer-pretty-printer
[sexlab-framework]: https://www.loverslab.com/topic/91861-sexlab-framework-se-163-beta-8-november-22nd-2019/
[sp]: https://www.nexusmods.com/skyrimspecialedition/mods/54909
[spid]: https://www.nexusmods.com/skyrimspecialedition/mods/36869
[tokyo-night]: https://marketplace.visualstudio.com/items?itemname=enkia.tokyo-night
[visual-studio-code]: https://code.visualstudio.com/
[vscode-papyrus]: https://marketplace.visualstudio.com/items?itemname=joelday.papyrus-lang-vscode
[zerobrane-studio]: https://studio.zerobrane.com/
