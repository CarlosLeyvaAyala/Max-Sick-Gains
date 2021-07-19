# Muscle definition

After many months of frustrating work trying to do this in [Sandow Plus Plus][], it seems I finally managed to make vary muscle definition without varying weight.

This approach doesn't use NiOverride for texture overriding, since it's quite fickle in Skyrim SE and it does whatever the hell it feels like. \
I suspect this is a problem with the new optimizations to nif files that were made for SE, but I have no way to confirm this.

# The method

Here's the overview:

## Non coding steps

1. Create zeroed-slider bodies in Bodyslide. This will prevent bodies from varying by weight.
1. Create a new naked armor with its respective armor addons in the CK.
1. Create your wanted muscle definition texture sets in the CK.
1. Create a formlist containing those texture sets.
1. Assign this formlist to the new armor addon.

This will create a body that has many different muscle definition levels according to weight.

This is mostly the way [SPP Ripped Bodies][] work, but here we are making a new naked body with its own list for each type of muscle definition we want (only fat textures, only fit textures...).

## Papyrus steps

1. Set `Actor` body shape using `NiOverride.SetMorphValue`. This will set the overall shape of the actor.
1. Assign your desired muscle definition by setting the actor skin to the new armor you created: `(npc.GetBaseObject() as ActorBase).SetSkin(customNakedArmor)`.

All previous steps decouple weight from appearance and body shape.

If you want to:

- Vary the appearance of the actor, as if changing weight: `NiOverride.SetMorphValue`.
- Vary muscle definition: `SetNPCWeight(newWeight)`.
- Switch to other kind of muscle definition: `BaseActor.SetSkin(otherNakedArmor)`

# Wrapping up

That's all there is to this mod.

Of course, the implementation of these ideas is an entirely different matter. \
There are many interpolations to make transitions smooth, managing variable, etc, but the general idea behind this mod is what you have seen in this page.

[Sandow Plus Plus]: https://github.com/CarlosLeyvaAyala/Sandow-Plus-Plus
[SPP Ripped Bodies]: https://www.nexusmods.com/skyrimspecialedition/mods/34632
