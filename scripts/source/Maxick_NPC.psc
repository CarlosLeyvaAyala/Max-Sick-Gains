Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

; FormList Property KnownNPCs Auto
Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto
Maxick_Debug Property md Auto
Maxick_Events Property ev Auto

Function OnGameReload()
EndFunction

Function Test()
EndFunction

; Can this NPC get NiOverride data applied?
bool Function CanApplyNiOverride(Actor npc)
EndFunction

; Force an NPC to get updated.
Function ForceUpdate()
EndFunction

Function ForceUpdateCrosshair()
EndFunction

; Gets an npc `ActorBase` by using `GetLeveledActorBase()`.
;
; Was made as a separate function because these alternatives were viable as well
; and may or may not be used instead:
; - npc.GetActorBase() <- Always gets 'dremora' as the NPC class. Not viable.
; - npc.GetBaseObject() <- Always gets 'dremora' as the NPC class. Not viable.
; - npc.GetLeveledActorBase()
ActorBase Function _GetBase(Actor npc)
  return npc.GetLeveledActorBase()
EndFunction

; Changes the appearance of some NPC based on their data.
Function ChangeAppearance(Actor npc)
EndFunction

; Changes an actor appearance while skipping optimizations.
Function ForceChangeAppearance(Actor npc, int appearance = 0)
EndFunction
