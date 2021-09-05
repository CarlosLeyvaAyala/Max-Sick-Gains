Scriptname Maxick_CellChangeStalker extends ObjectReference
{
  See: https://www.creationkit.com/index.php?title=Detect_Player_Cell_Change_(Without_Polling)
}

Actor property player auto

Maxick_Events property ev auto
Maxick_Debug Property md Auto

Event OnCellDetach()
  md.LogVerb("Player changed cells. Sending event from XMarker.")
  Utility.Wait(0.1) ;maybe not necessary
  MoveTo(player)
  SendModEvent(ev.CELL_CHANGE)
EndEvent
