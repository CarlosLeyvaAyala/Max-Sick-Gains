Scriptname Maxick_MeterBase extends DM_MeterWidgetScript Hidden

float Property Position Hidden
  float Function Get()
    return Percent * 100
  EndFunction
  Function Set(float value)
    Percent = value / 100
  EndFunction
EndProperty

; Flash path file.
string Function GetWidgetSource()
  Return "maxick/meter.swf"
EndFunction

; Id used for loading data from the Lua tree.
int Function Id()
  return 0
EndFunction

string Function Key()
  return "meter0"
EndFunction

Function FlashNow(int color)
  FlashColor = color
  ForceFlash()
EndFunction

Function LoadData(int data)
  ; FillDirection = "right"
  Width = JMap.getFlt(data, "meterW", 250.0)
  Height = JMap.getFlt(data, "meterH", 20.0)
  HAnchor = JMap.getStr(data, "hA", "right")
  VAnchor = JMap.getStr(data, "vA", "center")
  string p = ".meters." + Key() + "."
  X = JValue.solveFlt(data, p + "x")
  Y = JValue.solveFlt(data, p + "y")
  PrimaryColor = JValue.solveInt(data, p + "color")
  ; _SetGradientColor(JValue.solveInt(data, p + "color"))   ; Looks too bright
EndFunction

Function _SetGradientColor(int color)
  PrimaryColor = color
  SecondaryColor = _LighterCol(color, 0.2)
EndFunction

int Function _LighterCol(int c, float mag)
  int r = Math.RightShift(Math.LogicalAnd(c, 0xFF0000), 16)
  int g = Math.RightShift(Math.LogicalAnd(c, 0xFF00), 8)
  int b = Math.LogicalAnd(c, 0xFF)
  r = _LightenChannel(r, mag) * 0x010000
  g = _LightenChannel(g, mag) * 0x0100
  b = _LightenChannel(b, mag)
  return r + g + b
EndFunction

int Function _LightenChannel(int c, float magnitude)
  return Math.Floor(c + (0xFF - c) * magnitude)
EndFunction
