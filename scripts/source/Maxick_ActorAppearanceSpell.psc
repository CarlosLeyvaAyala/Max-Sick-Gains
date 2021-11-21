Scriptname Maxick_ActorAppearanceSpell extends ActiveMagicEffect
{
  This is the script that makes changes on NPCs.
  It's applied by a spell distributed via SPID.
}

Maxick_Debug Property md Auto
Maxick_ActorAppearance Property looksHandler Auto
Maxick_NPC Property NpcHandler Auto
Maxick_Events Property ev Auto
bool Property hasNiOverride Auto
Actor npc

string name

Event OnEffectStart(Actor akTarget, Actor akCaster)
EndEvent
