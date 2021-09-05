Scriptname Maxick_CellChangeTracker extends ActiveMagicEffect
{
  See: https://www.creationkit.com/index.php?title=Detect_Player_Cell_Change_(Without_Polling)
}
Actor property player auto
ObjectReference property XMarker auto

Maxick_Events property ev auto
Maxick_Debug Property md Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
  md.LogVerb("Player changed cells. Sending event from spell.")
  Utility.Wait(0.1) ; Required.
  XMarker.MoveTo(player)
  SendModEvent(ev.CELL_CHANGE)
EndEvent
