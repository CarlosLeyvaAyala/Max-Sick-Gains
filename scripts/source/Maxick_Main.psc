Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}
Actor Property Player Auto
FormList Property TexturesList  Auto
{A list that contains lists of textures used to change people's muscle definition levels}
string bodyN = "Body [Ovl0]"

Event OnUpdate()
  ; Wet Function compatibility
  _UpdateTextures()
  RegisterForSingleUpdate(2)
EndEvent

; Transfers one indexed property from the body to some overlay layer.
; Mostly used to transfer texture maps to overrides.
; At this stage, it's only used for compatibility with Wet Function Redux
Function _TransferOvIdx(Actor aAct, string node, int idx, bool isFem = true)
  string tx = NiOverride.GetSkinPropertyString(aAct, false, 0x04, 9, idx)
  float v = NiOverride.GetSkinPropertyFloat(aAct, false, 0x04, 9, idx)
  NiOverride.AddNodeOverrideString(aAct, isFem, node, 9, idx, tx, true)
  NiOverride.AddNodeOverrideFloat(aAct, isFem, node, 9, idx, v, true)
EndFunction

; Transfers one float property from the body to some overlay layer.
; At this stage, it's only used for compatibility with Wet Function Redux
Function _TransferOvFloat(Actor aAct, string node, int k, bool isFem = true)
  float v = NiOverride.GetSkinPropertyFloat(aAct, false, 0x04, k, -1)
  NiOverride.AddNodeOverrideFloat(aAct, isFem, node, k, -1, v, true)
EndFunction

TextureSet Function _GetTextureSet(Actor aAct)
  ; FIXME: Implement a real search based on actor settings
  return (TexturesList.GetAt(0) as FormList).GetAt(0) as TextureSet
EndFunction

Function _TransferOverrides(Actor aAct)
  ; FIXME: Check actor sex
  ;  Transfer skin
  int skincol = NiOverride.GetSkinPropertyInt(aAct, true, 0x80, 7, -1)
  NiOverride.AddNodeOverrideInt(aAct, true, bodyN, 7, -1, skincol, true)
  _TransferOvIdx(aAct, bodyN, 7)       ; Backlight mask / specular map
  _TransferOvFloat(aAct, bodyN, 2)     ; Glossiness power
  _TransferOvFloat(aAct, bodyN, 3)     ; Specular power
EndFunction

; Transfer values needed for compatibility with Wet Function
Function _UpdateTextures()
  ; Check this to learn about units
  ; https://www.creationkit.com/index.php?title=Unit
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 512, None, false)
  int i = npcs.length
  While i > 0
      i -= 1
      Actor npc = npcs[i]
      _TransferOverrides(npc)
  EndWhile
EndFunction

; First time TextureSet setting for actors
Function _SetTextureSets()
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
      i -= 1
      Actor npc = npcs[i]
      TextureSet tx = _GetTextureSet(npc)
      if !NiOverride.HasOverlays(npc)
        NiOverride.AddOverlays(npc)
      endif
      ; FIXME: Remove this
      ; NiOverride.RemoveAllSkinOverrides(npc, true, true, 0x04)

      ; Set texture
      NiOverride.AddNodeOverrideTextureSet(npc, true, bodyN, 6, -1, tx, true)
      ; Transfer everything else that matters
      _TransferOverrides(npc)
      ; NPCs seem to need this
      NiOverride.ApplyNodeOverrides(npc)
  EndWhile
EndFunction


Function OnGameReload()
  Player = Game.GetPlayer()
  ; nioverride.RemoveAllNodeOverrides()
  _SetTextureSets()
  ; Actor serana = Game.GetFormFromFile(0x002B74, "Dawnguard.esm") as Actor
  ; ; MiscUtil.PrintConsole(NiOverride.HasOverlays(serana))

  ; MiscUtil.PrintConsole(NiOverride.HasNodeOverride(serana, true, "Body [Ovl0]", 6, -1))
  _TestMorphs(Player)
  _TestMorphs(Game.GetFormFromFile(0x002B74, "Dawnguard.esm") as Actor)
  RegisterForSingleUpdate(2)
EndFunction

Function OnCellLoad()
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
      i -= 1
      _TestMorphs(npcs[i])
  EndWhile
EndFunction

Event OnInit()
  TextureSet tx = (TexturesList.GetAt(0) as FormList).GetAt(0) as TextureSet
  Player = Game.GetPlayer()
  NiOverride.AddSkinOverrideTextureSet(Player, true, true, 0x04, 6, -1, tx, true)
EndEvent

Function _TestMorphs(Actor aAct)
  MiscUtil.PrintConsole(DM_Utils.GetActorName(aAct))
  NiOverride.ClearMorphs(aAct)
  ; DM Flabby
  ; NiOverride.SetMorphValue(aAct, "AppleCheeks", 0.20)
  ; NiOverride.SetMorphValue(aAct, "Belly", 0.60)
  ; NiOverride.SetMorphValue(aAct, "BellyFrontUpFat_v2", 0.10)
  ; NiOverride.SetMorphValue(aAct, "BellySideDownFat_v2", 0.30)
  ; NiOverride.SetMorphValue(aAct, "BellyUnder_v2", 0.20)
  ; NiOverride.SetMorphValue(aAct, "BigBelly", 0.45)
  ; NiOverride.SetMorphValue(aAct, "BigTorso", 0.60)
  ; NiOverride.SetMorphValue(aAct, "BreastGravity2", 0.15)
  ; NiOverride.SetMorphValue(aAct, "BreastHeight", 0.20)
  ; NiOverride.SetMorphValue(aAct, "BreastTopSlope", 0.75)
  ; NiOverride.SetMorphValue(aAct, "BreastWidth", -0.50)
  ; NiOverride.SetMorphValue(aAct, "Breasts", 0.25)
  ; NiOverride.SetMorphValue(aAct, "BreastsNewSH", 0.30)
  ; NiOverride.SetMorphValue(aAct, "BreastsTogether", 0.25)
  ; NiOverride.SetMorphValue(aAct, "ChubbyArms", 0.55)
  ; NiOverride.SetMorphValue(aAct, "ChubbyButt", 1.00)
  ; NiOverride.SetMorphValue(aAct, "ChubbyLegs", 0.50)
  ; NiOverride.SetMorphValue(aAct, "ChubbyWaist", 0.60)
  ; NiOverride.SetMorphValue(aAct, "DoubleMelon", 0.15)
  ; NiOverride.SetMorphValue(aAct, "HipForward", 0.25)
  ; NiOverride.SetMorphValue(aAct, "HipNarrow_v2", 0.10)
  ; NiOverride.SetMorphValue(aAct, "Hips", 0.10)
  ; NiOverride.SetMorphValue(aAct, "LegsThin", 0.40)
  ; NiOverride.SetMorphValue(aAct, "NippleDown", 0.30)
  ; NiOverride.SetMorphValue(aAct, "NippleLength", 0.10)
  ; NiOverride.SetMorphValue(aAct, "NippleSize", 0.35)
  ; NiOverride.SetMorphValue(aAct, "NippleTip", 0.10)
  ; NiOverride.SetMorphValue(aAct, "ShoulderWidth", 0.30)
  ; NiOverride.SetMorphValue(aAct, "SternumHeight", 0.30)

  ; DM Athletic Nude
; NiOverride.SetMorphValue(aAct, "7B Lower", 0.70)
; NiOverride.SetMorphValue(aAct, "7B Upper", 0.30)
; NiOverride.SetMorphValue(aAct, "Arms", 0.60)
; NiOverride.SetMorphValue(aAct, "BigTorso", 0.20)
; NiOverride.SetMorphValue(aAct, "BreastCenter", 0.30)
; NiOverride.SetMorphValue(aAct, "BreastGravity2", 0.30)
; NiOverride.SetMorphValue(aAct, "BreastTopSlope", 0.20)
; NiOverride.SetMorphValue(aAct, "Breasts", 0.10)
; NiOverride.SetMorphValue(aAct, "BreastsTogether", 0.30)
; NiOverride.SetMorphValue(aAct, "ButtClassic", 0.20)
; NiOverride.SetMorphValue(aAct, "CBPC", 0.00)
; NiOverride.SetMorphValue(aAct, "CalfSize", 0.30)
; NiOverride.SetMorphValue(aAct, "ChubbyButt", 0.20)
; NiOverride.SetMorphValue(aAct, "DoubleMelon", 0.10)
; NiOverride.SetMorphValue(aAct, "ForearmSize", 0.40)
; NiOverride.SetMorphValue(aAct, "Innieoutie", 0.90)
; NiOverride.SetMorphValue(aAct, "MuscleAbs", 0.60)
; NiOverride.SetMorphValue(aAct, "MuscleArms", 0.20)
; NiOverride.SetMorphValue(aAct, "NippleDown", 0.50)
; NiOverride.SetMorphValue(aAct, "NippleManga", 0.20)
; NiOverride.SetMorphValue(aAct, "RoundAss", 0.25)
; NiOverride.SetMorphValue(aAct, "Waist", -0.50)

; DM Snu Snu Nude
; NiOverride.SetMorphValue(aAct, "7B Lower", 0.70)
; NiOverride.SetMorphValue(aAct, "7B Upper", 0.30)
; NiOverride.SetMorphValue(aAct, "Belly", -0.20)
; NiOverride.SetMorphValue(aAct, "BigBelly", -0.10)
; NiOverride.SetMorphValue(aAct, "BigTorso", 0.20)
; NiOverride.SetMorphValue(aAct, "BreastCenter", 0.30)
; NiOverride.SetMorphValue(aAct, "BreastGravity2", 0.30)
; NiOverride.SetMorphValue(aAct, "BreastHeight", 0.20)
; NiOverride.SetMorphValue(aAct, "BreastTopSlope", 0.20)
; NiOverride.SetMorphValue(aAct, "Breasts", 0.20)
; NiOverride.SetMorphValue(aAct, "BreastsTogether", 0.30)
; NiOverride.SetMorphValue(aAct, "ButtClassic", 0.20)
; NiOverride.SetMorphValue(aAct, "CalfSize", 0.90)
; NiOverride.SetMorphValue(aAct, "ChestWidth", 0.70)
; NiOverride.SetMorphValue(aAct, "ChubbyButt", 0.20)
; NiOverride.SetMorphValue(aAct, "DoubleMelon", 0.20)
; NiOverride.SetMorphValue(aAct, "ForearmSize", 0.60)
; NiOverride.SetMorphValue(aAct, "HipForward", 0.10)
; NiOverride.SetMorphValue(aAct, "HipUpperWidth", -0.40)
; NiOverride.SetMorphValue(aAct, "Hips", 0.10)
; NiOverride.SetMorphValue(aAct, "LegShapeClassic", 0.20)
; NiOverride.SetMorphValue(aAct, "MuscleAbs", 0.60)
; NiOverride.SetMorphValue(aAct, "MuscleArms", 0.40)
; NiOverride.SetMorphValue(aAct, "MuscleButt", 0.20)
; NiOverride.SetMorphValue(aAct, "MuscleLegs", 0.20)
; NiOverride.SetMorphValue(aAct, "NippleDown", 0.50)
; NiOverride.SetMorphValue(aAct, "NippleManga", 0.20)
; NiOverride.SetMorphValue(aAct, "RoundAss", 0.25)
; NiOverride.SetMorphValue(aAct, "ShoulderWidth", 0.35)
; NiOverride.SetMorphValue(aAct, "SlimThighs", 0.05)
; NiOverride.SetMorphValue(aAct, "Thighs", 0.40)
; NiOverride.SetMorphValue(aAct, "TummyTuck", 0.25)

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
  NiOverride.UpdateModelWeight(aAct)
EndFunction
