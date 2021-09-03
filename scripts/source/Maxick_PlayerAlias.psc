Scriptname Maxick_PlayerAlias extends ReferenceAlias
{Used to detect OnGameReload}

Quest Property OwnerQuest  Auto
{Who will execute all OnGameReload code?}

Event OnPlayerLoadGame()
  (GetOwningQuest() as Maxick_Main).OnGameReload()
EndEvent

Event OnCellLoad()
  ; (GetOwningQuest() as Maxick_Main).OnCellLoad()
endEvent
