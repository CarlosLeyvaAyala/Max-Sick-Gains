Scriptname Maxick_MCM extends MCM_ConfigBase
{All the work is done by [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000) (thankfully).}

Maxick_Widget Property widget Auto
Maxick_Events Property ev Auto

; Event OnGameReload()
;   parent.OnGameReload()
;   _RegisterEvents()
; EndEvent

; Function _RegisterEvents()
;   RegisterForModEvent()
; EndFunction

; Gets widget data from saved user settings and asks the widget to update itself
; using that data.
Function UpdateWidget()
  float x = GetModSettingFloat("fX:Widget")
  float y = GetModSettingFloat("fY:Widget")
  float w = GetModSettingFloat("fW:Widget")
  float h = GetModSettingFloat("fH:Widget")
  float vGap = GetModSettingFloat("fVgap:Widget")
  int hAlign = GetModSettingInt("iHalign:Widget")
  int vAlign = GetModSettingInt("iValign:Widget")
  widget.SetAppearanceance(x, y, h, w, vGap, hAlign, vAlign)
EndFunction
