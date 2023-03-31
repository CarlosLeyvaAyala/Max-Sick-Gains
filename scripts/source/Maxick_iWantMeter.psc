Scriptname Maxick_iWantMeter extends Quest
{ Simplify iWant meter calls }

import DM_Utils

int handle
iWant_Widgets iWidgets
int _percent = 0

Function _UpdatePercent()
  iWidgets.setMeterPercent(handle, _percent)
EndFunction

int Property LightColor Auto
int Property DarkColor Auto

int Property Percent
  { Meter percent position [0 .. 100] }
  int Function get()
    return _percent
  EndFunction
  Function set(int value)
    int mx = MaxI(value, 0)
    _percent = MinI(mx, 100)
    _UpdatePercent()
  EndFunction
EndProperty

Function ResetMeter(iWant_Widgets manager, int x, int y, bool isVisible = true, int xScale = 35, int yScale = 50)
  iWidgets = manager
  handle = iWidgets.loadMeter(x, y)
  iWidgets.setZoom(handle, xScale, yScale)
  _SetColor(LightColor, DarkColor)
  iWidgets.setTransparency(handle, 70)
  iWidgets.setMeterFillDirection(handle, "right")
  _UpdatePercent()
  
  if isVisible
    iWidgets.setVisible(handle)
  EndIf
EndFunction

Function _SetColor(int c1, int c2, int flash = 0xffffff)
  int r1 = _R(c1)
  int g1 = _G(c1)
  int b1 = _B(c1)
  int r2 = _R(c2)
  int g2 = _G(c2)
  int b2 = _B(c2)
  int rf = _R(flash)
  int gf = _G(flash)
  int bf = _B(flash)

  iWidgets.setMeterRGB(handle, r1, g1, b1, r2, g2, b2, rf, gf, bf)
EndFunction

int Function _R(int c)
  return Math.RightShift(Math.LogicalAnd(c, 0xFF0000), 16)
EndFunction

int Function _G(int c)
  return Math.RightShift(Math.LogicalAnd(c, 0xFF00), 8)
EndFunction

int Function _B(int c)
  return Math.LogicalAnd(c, 0xFF)
EndFunction

Function FlashNow(int flashColor)
  _SetColor(LightColor, DarkColor, flashColor)
  iWidgets.doMeterFlash(handle)
EndFunction