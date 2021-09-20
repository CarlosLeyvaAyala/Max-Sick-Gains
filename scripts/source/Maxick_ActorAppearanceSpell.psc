Scriptname Maxick_ActorAppearanceSpell extends ActiveMagicEffect
; FIXME: Doesn't really work. Mark for deletion.

Maxick_Debug Property md Auto
Maxick_ActorAppearance Property looksHandler Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
  md.LogVerb("Maxick Spell attached to " + akTarget)
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
  Armor arm = akBaseObject as Armor
  if !arm || !arm.IsCuirass() ; TODO: Can fail because some armors are badly setup. Find another method.
    return
  endIf
  md.LogVerb("An armor was equiped on " + akReference + ". Setting muscle definition.")
  _SetMuscleDef(akReference as Actor)
endEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
  Armor arm = akBaseObject as Armor
  if !arm || !arm.IsCuirass() ; TODO: Can fail because some armors are badly setup. Find another method.
    return
  endIf
  md.LogVerb("An armor was unequiped from " + akReference + ". Setting muscle definition.")
  _SetMuscleDef(akReference as Actor)
endEvent

; bool Function _IsNotCuirass(Armor arm)
;   return arm.GetSlotMask() == arm.RemoveSlotFromMask(0x4)
; EndFunction

Function _SetMuscleDef(Actor aAct)
  int appearance = Maxick_DB.GetMemoizedAppearance(aAct)
  If !appearance
    md.LogVerb("Can't set muscle definition because actor appearance hasn't yet been calculated.")
    return
  EndIf
  looksHandler.ApplyMuscleDef(aAct, appearance)
EndFunction
