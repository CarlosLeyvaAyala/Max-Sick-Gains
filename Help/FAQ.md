<!-- @import "help.less" -->
# FAQ

## I don't understand how to make this mod to work
If you don't manage to make this work after following all ==tutorials== and/or [setting off all muscle definition options][MCMTab], then this mod is too advanced for you[^Condescending].

[^Condescending]: I'm not trying to be a condescending asshole, trust me. This mod just can't be plug and play and it requires some modding knowledge on your part.

Play any other mod. I can't do this easier to work with.


## Will you port this to LE?
No. I don't have LE and don't see the point of going back to the 32 bits era.

However, if you want to backport it, be my guest.
I don't know how much help I can provide you on the conversion process, but don't be afraid to ask me anything about this mod.


## Will Charmers of the Reach...?
Stop right there. I don't want to deal with that mod.

Nothing wrong about it, but its implementation it's higly incompatible with some implementations from this mod.


## Does this work with _\<insert some race here\>_?
Bodyslide preset applying will work on any NPC that uses a body that supports Bodyslide morphs.
Just add your race name to the most appropiate _Racial Group_ (most likely, _Humanoids_), so this mod recognizes them.

**Muscle definition is an entirely different matter.**
It's no coincidence there are so many options to control who won't change muscle definition.

I won't get into technical details on why this is so complicated, because that requires an entire ==technical document==, but an easy way to know if your race is allowed to change muscle definition is to just try it.

To enable muscle definition for custom races...

* For players: check _Apply muscle definition_ in the [MCM tab][MCMTab].

* For NPCs: do as above and try to [add some Known NPCs][KnownNPCAdding] if your mod introduces new NPCs of that race.

At this point, many things could happen:

* **Your race looks damn fine**.
Congratulations. Go play the game and get hot by training.
&nbsp;

* **It looks right, but lacks some feature, like a succubus tail**.
Share your mod with me and ***maybe*** I can make a patch to make it work.
&nbsp;

* **There's a minor texture mismatch between hands/head and body** (mostly, coloring).
This is a complicated matter with no standard solution. It all depends on how the mod was made.
First try using [this][Fix tex mismatches]. If that doesn't work, ***I can try to see if a patch is viable when I feel like doing so***[^NotMyJob] and there's no warranty it can be done.
For example, _Charmers of the Reach_ seems to be a real pain in the ass when it comes to these kind of matters.

[^NotMyJob]: I don't want to sound rude, but I hope you understand tailoring this mod to every single user is not my job... and damn, I want to play this game too! Not spending the rest of my life working on this mod.

* **There's a major texture mismatch between hands/head and body**.
You are most likely using furries, yes? Then yiff in hell.
OK, that's not an answer (but a valid suggestion, nonetheless :v). The real answer is: ***I won't be doing a patch for that***. It would mean a major redesign of this mod and _Max Sick Gains.exe_; it's just too much work.


## Muscle definition is too complicated
Yeah. It's the most complex feature to get properly running... by far.

Don't waste your time getting marveled at the complex and arcane mysteries it entails.
If you don't understand it or just want to play the damn game without spending many frustrating hours trying to setup some obscure mod made by some random asshole, just uncheck all muscle definition options at the [MCM tab][MCMTab] and enjoy the game.


## How do I add _Known NPCs_ from non vanilla mods?
[Follow this procedure][KnownNPCAdding].


## Characters don't look as expected!
Some possible issues:

1. This mod is setup by default to work with **3BA 2.0** for women and **HIMBO 4.2** for men.
If you use any other body or version, you need to ==generate the sliders for it==.

1. You may be using an *.xml file that contains many Bodyslide presets. **This program only supports one preset per file**.

1. If the problem is a _Known NPC_, remember some NPCs have many different versions (ie. Rikke, Cicero...), so you need to add all versions of them to _Known NPCs_.

1. You may got unlucky and ==Skyrim refused to find all data needed to change an NPC appearance==. This is more of an annoyance than a serious problem and will eventually correct itself.

### How do I know if I have problem 2?
Open your *.xml preset file in Notepad or whatever.
<figure>
<img class="vImg" src="img/bs-xml-many-presets.png"/>
<figcaption>This is how an *.xml file looks like in Notepad++.</figcaption>
</figure>

This file is `CalienteTools\BodySlide\SliderPresets\CBBE.xml` (the default presets for CBBE) and each one of those marked lines is an individual preset.
This is exactly the kind of file this mod doesn't support.

Let' say, we want to extract _CBBE Curvy_ from here.

Just open Bodyslide, select _CBBE Curvy_ and click on _Save As..._

<figure>
<img class="hImg" src="img/bs-isolate-preset.png"/>
</figure>

Once saved your new file, use that in your ==_Fitness Stage_== instead of _CBBE.xml_.
That's all.

## Your mod doesn't apply changes to some NPCs
I'm quite aware about that, but ***there's nothing I can do about it***.

I use _PapyrusUtil_ for getting all NPCs inside the cell the player is located, and for some unknown reason, it sometimes finds an NPC but doesn't get all the data this mod needs to know for how to apply changes to them.
Hell... I don't even know if that is a _PapyrusUtil_ or a Skyrim issue.

If you enable console logging for this mod, you will see the NPC won't be named and their race will be blank as well, thus failing to even set the _Default Fitness Stage_ for them because if there's no race, my mod thinks they may very well be some piece of furniture.

_PapyrusUtil_ sometimes works again the first time you close and open the game, it sometimes may take many tries for it to work... but don't worry; it will eventually properly load the NPC data, and once it finds the NPC, expect them to never be at zero sliders once again.

## I got textures mismatches on some NPCs
Let me guess: this happens to followers from some mods you downloaded, am I right? And I could bet my life savings they all are women.

Disable this mod and check again if this happened before you installed it.
If the texture mismatch still happens, congratulations! You are using a mod that forces you to use the texture sets the mod author shoved down your throat, you lucky bastard!
[Use this script][Fix tex mismatches] to fix that bullshit.

This is a list[^TexBullshit] of mods that I know to cause those issues (and fixed with the script above):

* All Bijin mods
* The Ordinary Women
* Vilja
* Sofia the funny voiced follower (or something)

[^TexBullshit]: This is an ever growing list, by the way.
If you find some other mod that does that kind of evil thing, please report it back to me so I can add it here.

By the way, don't blame me if you swear this didn't happen before installing my mod but now it does. This mod uses your own installed textures precisely to avoid that.
Maybe you never noticed that issue until now, that my mod made that problem painfully obvious[^OrdinaryWomenTextures].

If my mod is actually causing those issues, add the terrible looking NPCs to _Known NPCs_ and disable muscle definition for them.

## I don't have fat textures for Khajiit or Argonians

Yeah, me neither.
That's why I generated the fat textures from the same textures I use for the plain looking bodies.

<figure>
<img class="hImg" src="img/tex-gen-fat-beast.jpg"/>
<figcaption>Yeah... fat beastmen have the same muscle definition as their plain counterparts.</figcaption>
</figure>

That's better than nothing.

## Why are Astrid and Afflicted banned by default from getting muscle definition?

This ban affects only the burned version of Astrid[^AstridSpoiler], who of course has no business being ripped/fat/whatever.

Afflicted are banned because they get the same texture mismatch problems you would get on... say, furries.
And getting them to work would mean ==doing the same amount of work I refuse to do== for other races people actually care about.


## Will you add skin variety to this mod?
**HELL, NO!**

Not that this thought never crossed my mind, but it turned out it's just too much work to get it done.

==Remember the pizza hands problem== with NiOverride?

<figure>
<img class="vImg" src="img/pizza-hands-diffuse.jpg"/>
<figcaption>Well, it also affects diffuse maps.</figcaption>
</figure>

That limitation would make me add even more records to _Max Sick Gains.esp_, thus making it not an esl file, breaking saved games, making baby Jesus cry, filling your game with scripts that will make your house explode and ultimately causing World War V to erupt.
Well, some of those things may not happen, but why risk the chances?

Also remember this: having a human (like me) filling an esp file with many thousands of records has an inherent great risk of introducing hard to track bugs.
It's no coincidence Skyrim is so bugged and needs so many unofficial patches to get it to properly work.

[^AstridSpoiler]: That was an spoiler for a 10+ years old game that was launched even for your toaster an it somehow just works, motherfucker.


[^OrdinaryWomenTextures]:A few years ago I suddenly noticed horrible coloring mismatches in the hands and heads of women modified by Bijin and The Ordinary Women. I swore it was some other mod I recently installed but it turned out to be that both those mods were the culprits all along.
But I never noticed that before, even after many years using both of them!


[Fix tex mismatches]: https://www.loverslab.com/files/file/18289-fix-texture-mismatches-lesewhatever/

[MCMTab]: TO-DO

[KnownNPCAdding]: TO-DO
