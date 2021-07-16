Scriptname Maxick_PlayerAlias extends ReferenceAlias
{Used to detect OnGameReload}

Quest Property OwnerQuest  Auto
{Who will execute all OnGameReload code?}

Event OnPlayerLoadGame()
  (GetOwningQuest() as Maxick_Main).OnGameReload()
EndEvent

Event OnCellLoad()
  MiscUtil.PrintConsole("################# OnCellLoad")
  (GetOwningQuest() as Maxick_Main).OnCellLoad()

  ; Debug.Trace("Every object in this cell has loaded its 3d")
endEvent
