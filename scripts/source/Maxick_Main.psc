Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}

Import JValue
import Maxick_Utils

Actor Property Player Auto
FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}
Maxick_NPC Property NpcHandler Auto
{Handles everything NPC related}

int _femSliders
int Property femSliders Hidden
  int Function Get()
    return _femSliders
  EndFunction
EndProperty

int _manSliders
int Property manSliders Hidden
  int Function Get()
    return _manSliders
  EndFunction
EndProperty


Event OnInit()
  Player = Game.GetPlayer()
  OnGameReload()
EndEvent


Function OnGameReload()
  Player = Game.GetPlayer()
  _femSliders = _LoadSliders("data/SKSE/Plugins/Maxick/fem-sliders.json")
  _manSliders = _LoadSliders("data/SKSE/Plugins/Maxick/man-sliders.json")
  NpcHandler.Init(self)
  OnCellLoad()
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

Function _ApplyBodyslide(Actor aAct, int bodyslide)
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

Function _ChangeAppearance(Actor aAct, int data)
  Log(JMap.getStr(data, "msg"))
  If !JMap.getInt(data, "shouldProcess")
    return
  EndIf
  ; FIXME: Check if this should be done
  _ApplyBodyslide(aAct, JMap.getObj(data, "bodySlide"))
  _ApplyMuscleDef(aAct, data)
EndFunction

Function OnCellLoad()
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
    If npcs[i] != Player
      _ChangeAppearance(npcs[i], NpcHandler.ProcessNpc(npcs[i]))
    EndIf
    i -= 1
  EndWhile
  _TestMorphs(Player)
  ; _SetTextureSets()
EndFunction

Function _TestMorphs(Actor aAct)
  NiOverride.ClearMorphs(aAct)
  _makeHot(aAct)
  NiOverride.UpdateModelWeight(aAct)
  ; <SetSlider.*name\s*="(.*)".*"big".*="(.*)"\/>
  ; NiOverride.SetMorphValue(aAct, "\1", 0.\2)
EndFunction

Function _makeHot(Actor aAct)
  ; DM Amazons 3BA Nude
  NiOverride.SetMorphValue(aAct, "7B Lower", 0.70)
  NiOverride.SetMorphValue(aAct, "7B Upper", 0.30)
  NiOverride.SetMorphValue(aAct, "AppleCheeks", 0.30)
  NiOverride.SetMorphValue(aAct, "AreolaSize", -0.30)
  NiOverride.SetMorphValue(aAct, "BackValley_v2", 0.70)
  NiOverride.SetMorphValue(aAct, "Belly", -0.20)
  NiOverride.SetMorphValue(aAct, "BigBelly", -0.10)
  NiOverride.SetMorphValue(aAct, "BigTorso", 0.40)
  NiOverride.SetMorphValue(aAct, "BreastCenter", 0.30)
  NiOverride.SetMorphValue(aAct, "BreastGravity2", 0.30)
  NiOverride.SetMorphValue(aAct, "BreastHeight", 0.40)
  NiOverride.SetMorphValue(aAct, "BreastTopSlope", 0.30)
  NiOverride.SetMorphValue(aAct, "Breasts", 0.20)
  NiOverride.SetMorphValue(aAct, "BreastsTogether", 0.30)
  NiOverride.SetMorphValue(aAct, "Butt", 0.20)
  NiOverride.SetMorphValue(aAct, "ButtSmall", 0.30)
  NiOverride.SetMorphValue(aAct, "CalfSize", 0.80)
  NiOverride.SetMorphValue(aAct, "CalfSmooth", -0.30)
  NiOverride.SetMorphValue(aAct, "ChestWidth", 0.70)
  NiOverride.SetMorphValue(aAct, "ChubbyArms", 0.15)
  NiOverride.SetMorphValue(aAct, "ChubbyButt", 0.15)
  NiOverride.SetMorphValue(aAct, "ChubbyLegs", 0.05)
  NiOverride.SetMorphValue(aAct, "Clit", 0.50)
  NiOverride.SetMorphValue(aAct, "CrotchGap", -0.50)
  NiOverride.SetMorphValue(aAct, "DoubleMelon", 0.20)
  NiOverride.SetMorphValue(aAct, "FeetFeminine", 0.50)
  NiOverride.SetMorphValue(aAct, "ForearmSize", 0.70)
  NiOverride.SetMorphValue(aAct, "HipForward", 0.10)
  NiOverride.SetMorphValue(aAct, "HipUpperWidth", -0.40)
  NiOverride.SetMorphValue(aAct, "Hips", 0.20)
  NiOverride.SetMorphValue(aAct, "Innieoutie", 0.50)
  NiOverride.SetMorphValue(aAct, "LegShapeClassic", 0.30)
  NiOverride.SetMorphValue(aAct, "MuscleAbs", 0.60)
  NiOverride.SetMorphValue(aAct, "MuscleArms", 0.40)
  NiOverride.SetMorphValue(aAct, "MuscleBack_v2", 0.20)
  NiOverride.SetMorphValue(aAct, "MuscleButt", 0.20)
  NiOverride.SetMorphValue(aAct, "MuscleLegs", 0.40)
  NiOverride.SetMorphValue(aAct, "NippleDown", 0.50)
  NiOverride.SetMorphValue(aAct, "NippleManga", 0.20)
  NiOverride.SetMorphValue(aAct, "NipplePerkiness", 0.20)
  NiOverride.SetMorphValue(aAct, "NippleUp", -0.40)
  NiOverride.SetMorphValue(aAct, "RoundAss", 0.10)
  NiOverride.SetMorphValue(aAct, "ShoulderWidth", 0.20)
  NiOverride.SetMorphValue(aAct, "SlimThighs", 0.20)
  NiOverride.SetMorphValue(aAct, "Thighs", 0.55)
  NiOverride.SetMorphValue(aAct, "TummyTuck", 0.25)
EndFunction


;>========================================================
;>===                    HELPERS                     ===<;
;>========================================================

; It seems GetSex won't work if used inside a Global function; it can't be added to a library.
bool Function IsFemale(Actor aAct)
  return aAct.GetLeveledActorBase().GetSex() == 1
EndFunction

; Gets the race for an actor as a string.
string Function GetRace(Actor aAct)
  return MiscUtil.GetActorRaceEditorID(aAct)
EndFunction
