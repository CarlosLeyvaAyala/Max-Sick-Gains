import { LinCurve } from "DM-Lib/Math"
import {
  AddNodeOverrideString,
  AddSkinOverrideString,
  ClearMorphs,
  RemoveAllReferenceOverrides,
  RemoveAllReferenceSkinOverrides,
  SetBodyMorph,
  UpdateModelWeight,
} from "Racemenu/nioverride"
import { Actor, NetImmerse } from "skyrimPlatform"
import {
  BsSlider,
  FitStage,
  muscleDefBanRace,
  MuscleDefinitionType,
  RacialGroup,
  Sex,
} from "../database"
import { LogI, LogIT, LogV } from "../debug"

/** An already calculated Bodyslide preset. Ready to be applied to an `Actor`. */
export type BodyslidePreset = Map<string, number>

/**
 * Calculates how a Bodyslide preset should look at some given weight.
 *
 * @param bs A raw Bodyslide preset
 * @param w At which weight the preset will be calculated.
 * @param warn Message to output when warnings/errors are found.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendBs(bs: object, w: number): BodyslidePreset {
  const r = new Map()
  for (const slN in bs) {
    // @ts-ignore
    const sl = bs[slN] as BsSlider
    const v = LinCurve({ x: 0, y: sl.min }, { x: 100, y: sl.max })(w)
    r.set(slN, v / 100)
  }

  return r
}

/**
 * Calculates how a woman Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the female preset from.
 * @param weight At which weight the preset will be calculated.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendFemBs(fitStage: FitStage, weight: number): BodyslidePreset {
  return BlendBs(fitStage.femBs, weight)
}

/**
 * Calculates how a man Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the male preset from.
 * @param weight At which weight the preset will be calculated.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendManBs(fitStage: FitStage, weight: number): BodyslidePreset {
  return BlendBs(fitStage.manBs, weight)
}

/**
 * Returns a fully calculated Bodyslide preset for some Fitness Stage, sex and weight.
 *
 * @param fs Fitness Stage.
 * @param s Sex.
 * @param w Weight. [`0..100`].
 * @returns Fully calculated Bodyslide preset. Ready to be applied to an `Actor`.
 */
export function GetBodyslide(fs: FitStage, s: Sex, w: number): BodyslidePreset {
  LogV(`Fitness stage applied: ${fs.iName}`)
  return s === Sex.male ? BlendManBs(fs, w) : BlendFemBs(fs, w)
}

function MarkProcessed(a: Actor) {
  SetBodyMorph(a, "MaxickProcessed", "Maxick", 1)
}

export function ApplyBodyslide(a: Actor, bs: BodyslidePreset) {
  ClearMorphs(a)

  bs.forEach((v, sl) => {
    SetBodyMorph(a, sl, "Maxick", v)
  })

  UpdateModelWeight(a)
  MarkProcessed(a) // Need to mark the actor again due to clearing bodyslides
}

export function ApplyMuscleDef(a: Actor, s: Sex, path: string | undefined) {
  if (!path) return // TODO: Unequip pizza hands fix

  // TODO: EquipPizzaHandsFix(aAct, false)
  AddSkinOverrideString(a, s === Sex.female, false, 0x4, 9, 1, path, true)
  AddSkinOverrideString(a, s === Sex.female, true, 0x4, 9, 1, path, true)
  FixGenitalTextures(a)
}

export function ClearAppearance(a: Actor | null) {
  ClearMorphs(a)
  RemoveAllReferenceOverrides(a)
  RemoveAllReferenceSkinOverrides(a)
}

export function FixGenitalTextures(a: Actor) {
  Fix3BAGenitals(a)
}

function Fix3BAGenitals(a: Actor) {
  const b = "textures\\actors\\character\\female\\femalebody_etc_v2_1"
  const d = b + ".dds"
  const n = b + "_msn.dds"
  const sk = b + "_sk.dds"
  const s = b + "_s.dds"
  NodeOverride(a, true, "3BA_Vagina", d, n, sk, s)
  NodeOverride(a, true, "3BA_Anus", d, n, sk, s)
  NodeOverride(a, true, "3BBB_Vagina", d, n, sk, s)
  NodeOverride(a, true, "3BBB_Anus", d, n, sk, s)
}

function NodeOverride(
  a: Actor,
  isFem: boolean,
  node: string,
  diffuse: string,
  normal: string,
  skin: string,
  specular: string
) {
  if (!NetImmerse.hasNode(a, node, false)) return

  LogV(`Fixing genital node: ${node}`)
  AddNodeOverrideString(a, isFem, node, 9, 0, diffuse, false)
  AddNodeOverrideString(a, isFem, node, 9, 1, normal, false)
  AddNodeOverrideString(a, isFem, node, 9, 2, skin, false)
  AddNodeOverrideString(a, isFem, node, 9, 7, specular, false)
}

export function GetMuscleDefTex(
  s: Sex,
  r: RacialGroup,
  type: MuscleDefinitionType,
  lvl: number
) {
  const ss = s === Sex.female ? "Fem" : "Man"
  const n = lvl.toString().padStart(2, "0")
  const t =
    type === MuscleDefinitionType.plain
      ? "Meh"
      : type === MuscleDefinitionType.athletic
      ? "Fit"
      : "Fat"

  return LogIT(
    "Applied muscle definition",
    `actors\\character\\Maxick\\${RacialGroup[r]}\\${ss}${t}_${n}.dds`
  )
}

/** Performs a linear interpolation based on some `weight`.
 *
 * @param y1 Starting value.
 * @param y2 Ending value.
 * @param weight `Actor` `weight` to get the interpolated value at.
 * @returns The value associated to `weight`.
 */
export function InterpolateW(y1: number, y2: number, weight: number) {
  return LinCurve({ x: 0, y: y1 }, { x: 100, y: y2 })(weight)
}

/** Gets which muscle definition level an `Actor` should have.
 *
 * @param lo Minimum muscle definition level.
 * @param hi Maximum muscle definition level.
 * @param weight `Actor` weight.
 * @returns The muscle definition level that will be applied to the `Actor`.
 */
export function InterpolateMusDef(lo: number, hi: number, weight: number) {
  return Math.round(InterpolateW(lo, hi, weight))
}

export function IsMuscleDefBanned(raceEDID: string) {
  const r = raceEDID.toLowerCase()
  const isBanned =
    muscleDefBanRace.filter((ban, _, __) => r.indexOf(ban) >= 0).length > 0
  if (isBanned) LogI("Can't change muscle definition. Race is banned.")
  return isBanned
}
