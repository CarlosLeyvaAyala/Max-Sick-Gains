Scriptname Maxick_MeterBase extends DM_MeterWidgetScript Hidden

Maxick_Debug Property md Auto

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

Function SetData(int data, float H, float W, int hAlign, int vAlign)
  md.LogVerb("Setting " + WidgetName + " data")
  FillDirection = "right"
  Width = W
  Height = H
  HAnchor = JValue.evalLuaStr(0, "return maxick.HAlign[" + hAlign + "]")
  VAnchor = JValue.evalLuaStr(0, "return maxick.VAlign[" + vAlign + "]")

  string p = "." + WidgetName + "."
  X = JValue.solveFlt(data, p + "x")
  Y = JValue.solveFlt(data, p + "y")

  md.LogVerb(Key() + ".dataTree: " + data)
  md.LogVerb(Key() + ".x: " + X)
  md.LogVerb(Key() + ".y: " + Y)
  md.LogVerb(Key() + ".width: " + W)
  md.LogVerb(Key() + ".height: " + H)
  md.LogVerb(Key() + ".height: " + H)
  md.LogVerb(Key() + ".HAnchor: " + HAnchor)
  md.LogVerb(Key() + ".VAnchor: " + VAnchor)
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
