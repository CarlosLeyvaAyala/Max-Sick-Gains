Scriptname Maxick_Player extends Quest
{Player management}

import Maxick_Utils

Maxick_Main Property main Auto

Function TrainSkill(string aSkill)
  ; code
EndFunction

int Function _InitData(Actor player)
  int data = JMap.object()
  ; Shared data with NPC
  ; TODO: Factorize
  bool isFem = main.IsFemale(player)
  JMap.setInt(data, "isFem", isFem as int)
  If isFem
    JMap.setObj(data, "bodySlide",  JValue.deepCopy(JDB.solveObj(".maxick.femSliders")))
  Else
    JMap.setObj(data, "bodySlide", JValue.deepCopy(JDB.solveObj(".maxick.manSliders")))
  EndIf

  JMap.setStr(data, "raceEDID", main.GetRace(player))
  JMap.setInt(data, "muscleDefType", -1)
  JMap.setInt(data, "muscleDef", -1)

  ; Unique data to player
  JMap.setInt(data, "stage", 1)       ; Current player stage
  JMap.setFlt(data, "training", 0)
  JMap.setFlt(data, "gains", 0)
  JMap.setFlt(data, "headSize", 0.0)

  JMap.setInt(data, "evChangeStage", 0)

  return data
EndFunction

int Function GetAppearance(Actor player)
  return JValue.evalLuaObj(_InitData(player), "return maxick.ChangePlayerAppearance(jobject)")
EndFunction
