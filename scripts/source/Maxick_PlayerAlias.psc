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
