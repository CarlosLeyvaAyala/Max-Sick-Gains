Scriptname Maxick__Addon_trainingWeightSpawn extends ObjectReference
{Create and place a new activator for the player to train.}

Import Math

Activator Property trainingWeight Auto
{Activator to spawn}

MiscObject Property spawner Auto
{Misc item that spawned the activator}

Event OnEquipped(Actor _)
EndEvent
