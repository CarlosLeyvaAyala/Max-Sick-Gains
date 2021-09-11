Scriptname Maxick_PlayerAlias extends ReferenceAlias
{Used to detect OnGameReload}

Maxick_Debug Property md Auto
Maxick_Player Property player Auto
Quest Property OwnerQuest  Auto
{Who will execute all OnGameReload code?}

Event OnPlayerLoadGame()
  (GetOwningQuest() as Maxick_Main).OnGameReload()
EndEvent

Event OnCellLoad()
  ; (GetOwningQuest() as Maxick_Main).OnCellLoad()
endEvent

Event OnRaceSwitchComplete()
  md.LogVerb("Player changed race. OnRaceSwitchComplete() was gotten.")
  player.OnTransformation()
EndEvent

; Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
;   if akBaseObject as Armor
;     md.Log("An armor was equiped on the player. Setting muscle definition.")
;   endIf
; endEvent

; Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
;   if akBaseObject as Armor
;     md.Log("An armor was unequiped from the player. Setting muscle definition.")
;   endIf
; endEvent
