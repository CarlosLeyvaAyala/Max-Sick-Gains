Scriptname Maxick_ActorAppearanceSpell extends ActiveMagicEffect

Maxick_Debug Property md Auto
Maxick_ActorAppearance Property looksHandler Auto
Maxick_NPC Property NpcHandler Auto
Actor npc
string name

Event OnEffectStart(Actor akTarget, Actor akCaster)
  npc = akTarget
  name = DM_Utils.GetActorName(npc)
  md.LogVerb("+++++++++++++++++++ Maxick Spell attached to " + name)
  md.SetLuaLoggingLvl()
  NpcHandler.ChangeAppearance(npc)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  md.LogVerb("------------------- Maxick Spell finished on " + name)
  Clear()
endEvent

Event OnDetachedFromCell()
  md.LogVerb("------------------- OnDetachedFromCell " + name)
  Clear()
endEvent

Event OnCellDetach()
  md.LogVerb("------------------- OnCellDetach " + name)
  Clear()
EndEvent

Event OnUnload()
  md.LogVerb("------------------- OnUnload " + name)
  Clear()
EndEvent

; Clears NiOverride values to avoid save game bloat.
Function Clear()
  ; md.LogVerb("Has morphs added by this mod: " + NiOverride.HasBodyMorphKey(npc, "Maxick"))
  If looksHandler.clearAllOverrides
    md.LogVerb("All 'NiOverrides' will be cleared.")
    ClearAllNiOverrideData()
  Else
    md.LogVerb("Only 'NiOverrides' added by this mod will be cleared.")
    looksHandler.ClearMorphs(npc)
  EndIf
EndFunction

; Experimental method that clears all NiOverride data on `Actors` that were unloaded from game.
; May delay save game bloat a great deal or may break some mods.
Function ClearAllNiOverrideData()
  NiOverride.ClearMorphs(npc)
  NiOverride.RemoveAllReferenceOverrides(npc)
  ; NiOverride.RemoveAllReferenceSkinOverrides(npc)
EndFunction
