Scriptname Maxick_PlayerAlias extends ReferenceAlias
{Used to detect OnGameReload}

Maxick_Debug Property md Auto
Maxick_Player Property player Auto
; Quest Property OwnerQuest  Auto
; {Who will execute all OnGameReload code?}
Armor Property PizzaHandsFix Auto

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

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
  ; TODO: Factorize GetModSettingBool to make it less dependable on names
  If MCM.GetModSettingBool("Max Sick Gains", "bPlMusDef:Appearance")
    player.EquipPizzaHandsFix()
    player.FixGenitalTextures()
  EndIf
endEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
  If MCM.GetModSettingBool("Max Sick Gains", "bPlMusDef:Appearance")
    player.FixGenitalTextures()
  EndIf
EndEvent
