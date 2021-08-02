Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}
Import JValue

Actor Property Player Auto
FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}

; First time TextureSet setting for actors
Function _SetTextureSets()
  string root = "maxickGains"
  ; https://www.creationkit.com/index.php?title=Unit
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
      i -= 1
      Actor npc = npcs[i]
      ActorBase b = npc.GetBaseObject() as ActorBase
      ; int rand = Utility.RandomInt(0, 2)
      ; b.SetSkin(NakedBodiesList.GetAt(1) as Armor)
      ; npc.QueueNiNodeUpdate()

      ; MiscUtil.PrintConsole("###########################################")
      ; MiscUtil.PrintConsole(DM_Utils.GetActorName(npc))
      ; MiscUtil.PrintConsole("b skin = " + b.GetSkin())
      ; MiscUtil.PrintConsole("b skin = " + b.GetFormID())
      ; MiscUtil.PrintConsole("b rand = " + rand)
      ; MiscUtil.PrintConsole("b class = " + b.GetClass().GetName())
      ; MiscUtil.PrintConsole("###########################################")

      ; MiscUtil.PrintConsole("b class = " + b.GetClass())
      ; MiscUtil.PrintConsole("l class = " + npc.GetLeveledActorBase().GetClass())
      ; MiscUtil.PrintConsole("l class = " + npc.GetLeveledActorBase().GetClass().GetName())
  EndWhile
  ; JValue.writeToFile(JDB.solveObj("." + root), JContainers.userDirectory() + "Maxick.json")
  ; MiscUtil.PrintConsole(JContainers.userDirectory() + "Maxick.json")
EndFunction

int _femSliders
int _knownNpcs

; Initializes gets known sliders from some file and inits them at 0.0
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

Function OnGameReload()
  Player = Game.GetPlayer()
  _femSliders = _LoadSliders("data/SKSE/Plugins/Maxick/fem-sliders.json")
  _knownNpcs = JValue.readFromFile("data/SKSE/Plugins/Maxick/npcs.json")
  OnCellLoad()
  ; Actor serana = Game.GetFormFromFile(0x002B74, "Dawnguard.esm") as Actor
  ; ; MiscUtil.PrintConsole(NiOverride.HasOverlays(serana))

  ; MiscUtil.PrintConsole(NiOverride.HasNodeOverride(serana, true, "Body [Ovl0]", 6, -1))
  ; _TestMorphs(Player)
  ; _TestMorphs(Game.GetFormFromFile(0x002B74, "Dawnguard.esm") as Actor)
  ; RegisterForSingleUpdate(2)
EndFunction

Function _ProcessNpc(Actor npc)
  int data = JMap.object()
  bool isFem = _IsFemale(npc)
  JMap.setInt(data, "isFem", isFem as int)
  JMap.setStr(data, "msg", "")
  ActorBase base = npc.GetBaseObject() as ActorBase
  MiscUtil.PrintConsole("=====")
  MiscUtil.PrintConsole("Testing " + DM_Utils.GetActorName(npc))
  MiscUtil.PrintConsole("=====")
  if !JFormMap.hasKey(_knownNpcs, base)
    MiscUtil.PrintConsole("||||||||Fail 1")
    base = npc.GetLeveledActorBase()
    if !JFormMap.hasKey(_knownNpcs, base)
      MiscUtil.PrintConsole("||||||||Fail 2")
      base = npc.GetActorBase()
    endif
  endif

  JMap.setFlt(data, "weight", base.GetWeight())
  If isFem
    JMap.setObj(data, "bodySlide", _femSliders)
  EndIf

  MiscUtil.PrintConsole("Testing actor " + base.GetFormID())
  ; MiscUtil.PrintConsole("|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||")
  ; JFormMap.setStr(_knownNpcs, npc, "passed here")
  ; JValue.writeToFile(_knownNpcs, JContainers.userDirectory() + "__Maxick known.json")
  ; MiscUtil.PrintConsole(JFormMap.getObj(_knownNpcs, npc))
  ; MiscUtil.PrintConsole("|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||")

  If JFormMap.hasKey(_knownNpcs, base)
    MiscUtil.PrintConsole("|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||")
    MiscUtil.PrintConsole("*** KNOWN NPC *** " + DM_Utils.GetActorName(npc))
    int values = JFormMap.getObj(_knownNpcs, base)
    JMap.setInt(data, "fitStage", JMap.getInt(values, "fitStage"))
    JMap.setInt(data, "weight", JMap.getInt(values, "weight"))
    JMap.setInt(data, "muscleDef", JMap.getInt(values, "muscleDef"))
    JMap.setInt(data, "shouldProcess", 1)
    int result = JValue.evalLuaObj(data, "return maxick.ProcessKnownNPC(jobject)")
    _ApplyBodyslide(npc, JMap.getObj(result, "bodySlide"))
    MiscUtil.PrintConsole(JMap.getStr(result, "msg"))
  EndIf

  return

  JMap.setInt(data, "shouldProcess", 0) ; We still don't know if npc should be processed
  JMap.setForm(data, "id", npc)
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

Function OnCellLoad()
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
    If npcs[i] != Player
      _ProcessNpc(npcs[i])
    EndIf
    i -= 1
  EndWhile
  _TestMorphs(Player)
  ; _SetTextureSets()
EndFunction

Event OnInit()
  Player = Game.GetPlayer()
EndEvent

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
bool Function _IsFemale(Actor aAct)
  return aAct.GetLeveledActorBase().GetSex() == 1
EndFunction

; Gets the race for an actor as a string.
string Function _GetRace(Actor aAct)
  return MiscUtil.GetActorRaceEditorID(aAct)
EndFunction
