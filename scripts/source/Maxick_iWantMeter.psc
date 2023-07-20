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

int Property XScale = 35 Auto
int Property YScale= 46 Auto

; Start the widget out of view, then wait for the data coming from typescript
int Property X = 1000 Auto 
int Property Y = 1000 Auto

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

Function ResetMeter(iWant_Widgets manager, bool isVisible = true)
  iWidgets = manager
  handle = iWidgets.loadMeter(X, Y)
  iWidgets.setZoom(handle, XScale, YScale)
  _SetColor(LightColor, DarkColor)
  iWidgets.setTransparency(handle, 80)
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

Function MoveToXY()
  float secs = 0.1
  iWidgets.doTransitionByTime(handle, X, secs, "x")
  iWidgets.doTransitionByTime(handle, Y, secs, "y")
EndFunction

Function SetScale()
  float secs = 0.1
  iWidgets.doTransitionByTime(handle, XScale, secs, "xscale")
  iWidgets.doTransitionByTime(handle, YScale, secs, "yscale")
EndFunction