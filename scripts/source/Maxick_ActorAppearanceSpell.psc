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

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
  If NpcHandler.CanApplyNiOverride(npc)
    looksHandler.EquipPizzaHandsFix(npc)
    looksHandler.FixGenitalTextures(npc)
  EndIf
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
  If NpcHandler.CanApplyNiOverride(npc)
    looksHandler.FixGenitalTextures(npc)
  EndIf
EndEvent

; Make sure NPC appearance is restored after reloading a save.
; Event OnGameReloaded(string _, string __, float ___, form ____)
;   md.LogVerb("///////////////////////// Maxick Spell OnGameReloaded: " + name)
;   ; ChangeAppearance()
; EndEvent

Event OnEffectStart(Actor akTarget, Actor akCaster)
  ; RegisterEvents()
  npc = akTarget
  name = DM_Utils.GetActorName(npc)
  If looksHandler.IsChild(npc)
    md.LogVerb("+++++++++++++++++++ Maxick Spell attached to child " + name + ". Skipping.")
  EndIf
  md.LogVerb("+++++++++++++++++++ Maxick Spell attached to " + name)

  ; Wait for avoiding infinite loading screens
  Utility.Wait(Utility.RandomFloat(0, 0.2))

  ; looksHandler.EquipPizzaHandsFix(npc, false)   ; This is the step that makes possible to use NiOverride at all.
  ChangeAppearance()
EndEvent

Event OnLoad()
  md.LogVerb("///////////////////////// Maxick Spell OnLoad: " + name)
  ; RegisterEvents()
  ChangeAppearance()
EndEvent

Event OnAttachedToCell()
  md.LogVerb("///////////////////////// Maxick Spell OnAttachedToCell: " + name)
  RegisterEvents()
  ChangeAppearance()
EndEvent

Event OnCellAttach()
  md.LogVerb("///////////////////////// Maxick Spell OnCellAttach: " + name)
  RegisterEvents()
  ChangeAppearance()
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
  UnregisterForModEvent(ev.GAME_RELOADED)

  If looksHandler.clearAllOverrides
    md.LogVerb("All 'NiOverrides' will be cleared. " + name)
    ClearAllNiOverrideData()
  Else
    md.LogVerb("Only 'NiOverrides' added by this mod will be cleared. " + name)
    looksHandler.Clear(npc)
  EndIf
EndFunction

; Experimental method that clears all NiOverride data on `Actors` that were unloaded from game.
; May delay save game bloat a great deal or may break some mods.
Function ClearAllNiOverrideData()
  NiOverride.ClearMorphs(npc)
  NiOverride.RemoveAllReferenceOverrides(npc)
  NiOverride.RemoveAllReferenceSkinOverrides(npc)
EndFunction

Function ChangeAppearance()
  If npc.IsDisabled()
    md.LogVerb(name + " is disabled. Ignore. ************************************")
  EndIf
  GoToState("ChangingAppearance")

  md.SetLuaLoggingLvl()
  NpcHandler.ChangeAppearance(npc)

  If !npc.GetParentCell().IsAttached()
    md.LogVerb(name + " got detached while setting appearance. Cleaning. ************************************")
    Clear()
  EndIf
  GoToState("")
EndFunction

State ChangingAppearance
  Function ChangeAppearance()
    md.LogVerb(name + " tried to change appearance while an appearance changing process was running. Ignore.")
  EndFunction
EndState

Function RegisterEvents()
  ; RegisterForModEvent(ev.GAME_RELOADED, "OnGameReloaded")
EndFunction
