Scriptname Maxick_ActorAppearance extends Quest

import Maxick_Utils

FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}

;>========================================================
;>===                    SLIDERS                     ===<;
;>========================================================

Function InitSliders()
  int data = JMap.object()
  JMap.setObj(data, "femSliders", _LoadSliders("data/SKSE/Plugins/Maxick/fem-sliders.json"))
  JMap.setObj(data, "manSliders", _LoadSliders("data/SKSE/Plugins/Maxick/man-sliders.json"))
  JDB.setObj("maxick", data)
EndFunction

; Initializes known sliders from some file and inits them at `0.0`
; Posible sliders need to be known before we can change their values on a
; per `Actor` basis.
int Function _LoadSliders(string aPath)
  int result = JMap.object()
  int sliders = JValue.readFromFile(aPath)
  int i = JArray.count(sliders)
  While (i > 0)
    i -= 1
    JMap.setFlt(result, JArray.getStr(sliders, i), 0.0)
  EndWhile
  return result
EndFunction

;>========================================================
;>===                      CORE                      ===<;
;>========================================================

Function _ApplyBodyslide(Actor aAct, int bodyslide)
  ; FIXME: Check if this should be done
  NiOverride.ClearMorphs(aAct)

  string slider = JMap.nextKey(bodyslide)
  While slider != ""
    NiOverride.SetMorphValue(aAct, slider, JMap.getFlt(bodyslide, slider))
    slider = JMap.nextKey(bodyslide, slider)
  EndWhile

  NiOverride.UpdateModelWeight(aAct)
EndFunction

Function _ApplyMuscleDef(Actor aAct, int data)
  int muscleDefType = JMap.getInt(data, "muscleDefType")
  If muscleDefType >= 0
    int muscleDef = JMap.getInt(data, "muscleDef")

    ActorBase b = aAct.GetBaseObject() as ActorBase
    FormList defType = NakedBodiesList.GetAt(muscleDefType) as FormList
    b.SetSkin(defType.GetAt(muscleDef) as Armor)
    ; FIXME: Check that the actor is not mounting before doing this
    aAct.QueueNiNodeUpdate()
  EndIf
EndFunction

Function ChangeAppearance(Actor aAct, int data)
  Log(JMap.getStr(data, "msg"))
  ; Defaults to 1 because the player doesn't need this value. She is always processed.
  If !JMap.getInt(data, "shouldProcess", 1)
    return
  EndIf
  _ApplyBodyslide(aAct, JMap.getObj(data, "bodySlide"))
  _ApplyMuscleDef(aAct, data)
EndFunction

;>========================================================
;>===                    HELPERS                     ===<;
;>========================================================

; Gets if the actor is a female.
bool Function IsFemale(Actor aAct)
  ; It seems `GetSex()` won't work if used inside a Global function; it can't be added to a library.
  return aAct.GetLeveledActorBase().GetSex() == 1
EndFunction

; Gets the race EDID for an actor as a string.
string Function GetRace(Actor aAct)
  return MiscUtil.GetActorRaceEditorID(aAct)
EndFunction

; Initializes data shared between actors processed by this mod:
; * Sex
; * Sliders
; * Race EDID
; * Muscle definition
; * Muscle definition type
; * Weight
Function InitCommonData(int data, Actor aAct, float weight)
  bool isFem = IsFemale(aAct)
  JMap.setInt(data, "isFem", isFem as int)
  If isFem
    JMap.setObj(data, "bodySlide",  JValue.deepCopy(JDB.solveObj(".maxick.femSliders")))
  Else
    JMap.setObj(data, "bodySlide", JValue.deepCopy(JDB.solveObj(".maxick.manSliders")))
  EndIf

  JMap.setStr(data, "raceEDID", GetRace(aAct))
  JMap.setInt(data, "muscleDefType", -1)
  JMap.setInt(data, "muscleDef", -1)
  JMap.setFlt(data, "weight", weight)
EndFunction
