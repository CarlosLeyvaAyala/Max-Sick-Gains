import { waitActor } from "DmLib/Actor"
import { IntToHex, LoggingFunction, TappedFunction } from "DmLib/Log"
import { LinCurve } from "DmLib/Math"
import {
  AddNodeOverrideString,
  AddSkinOverrideString,
  ClearMorphs,
  GetSkinOverrideString,
  TextureIndex as Idx,
  Key,
  Key as NiOKey,
  RemoveAllReferenceOverrides,
  RemoveAllReferenceSkinOverrides,
  RemoveSkinOverride,
  SetBodyMorph,
  UpdateModelWeight,
} from "Racemenu/nioverride"
import {
  Actor,
  ActorBase,
  Armor,
  Game,
  NetImmerse,
  SlotMask,
} from "skyrimPlatform"
import {
  BsSlider,
  FitStage,
  MuscleDefinitionType,
  RacialGroup,
  Sex,
  muscleDefBanRace,
} from "../database"
import { LogE, LogI, LogIT, LogV, LogVT } from "../debug"
import { BodyslidePreset } from "./bodyslide"

export function LogBs(
  bs: BodyslidePreset | undefined,
  name: string,
  Log: (msg: any) => void
) {
  if (!bs) return

  Log("------------------------------")
  Log(name)
  Log("------------------------------")

  bs.forEach((v, k) => {
    Log(`${k}: ${v}`)
  })

  Log("------------------------------")
}

/** A function that calculates a slider value.
 * @param slMin Minimum slider value.
 * @param slMax Maximum slider value.
 * @param w Interpolation point.
 */
type BsCalc = (slMin: number, slMax: number, w: number) => number

/** Standard morph. Applies a simple linear interpolation between data.
 *
 * @param min Minimum slider value.
 * @param max Maximum slider value.
 * @param w Interpolation point.
 * @returns Interpolated value.
 */
const StdMorph: BsCalc = (min, max, w) =>
  LinCurve({ x: 0, y: min }, { x: 100, y: max })(w)

export const BlendMorph =
  (blend: number) => (min: number, max: number, w: number) =>
    StdMorph(min, max, w) * blend

/** Calculates how a Bodyslide preset should look at some given weight.
 *
 * @param bs A raw Bodyslide preset
 * @param w At which weight the preset will be calculated.
 * @param Morph Interpolation function.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendBs(bs: object, w: number, Morph: BsCalc): BodyslidePreset {
  const r = new Map()
  for (const slN in bs) {
    // @ts-ignore
    const sl = bs[slN] as BsSlider
    const v = Morph(sl.min, sl.max, w) / 100
    r.set(slN, v)
  }

  return r
}

/** Calculates how a woman Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the female preset from.
 * @param weight At which weight the preset will be calculated.
 * @param Morph Interpolation function.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendFemBs(
  fitStage: FitStage,
  weight: number,
  Morph: BsCalc
): BodyslidePreset {
  return BlendBs(fitStage.femBs, weight, Morph)
}

/** Calculates how a man Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the male preset from.
 * @param weight At which weight the preset will be calculated.
 * @param Morph Interpolation function.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
function BlendManBs(
  fitStage: FitStage,
  weight: number,
  Morph: BsCalc
): BodyslidePreset {
  return BlendBs(fitStage.manBs, weight, Morph)
}

/**  Returns a fully calculated Bodyslide preset for some Fitness Stage, sex and weight.
 *
 * @param fs Fitness Stage.
 * @param s Sex.
 * @param w Weight. [`0..100`].
 * @param Morph Interpolation function. This is used to calculate individual sliders.
 * @returns Fully calculated Bodyslide preset. Ready to be applied to an `Actor`.
 */
export function GetBodyslide(
  fs: FitStage,
  s: Sex,
  w: number,
  Morph: BsCalc = StdMorph,
  Log: LoggingFunction = LogV
): BodyslidePreset {
  Log(`Fitness stage applied: ${fs.iName}`)
  return s === Sex.male ? BlendManBs(fs, w, Morph) : BlendFemBs(fs, w, Morph)
}

/** Clears all NiOverride data on an `Actor`.
 * @remarks
 * Used to avoid save game bloat.
 *
 * @param a Actor to clear appearance for.
 */
export function ClearAppearance(a: Actor | null) {
  ClearMorphs(a)
  RemoveAllReferenceOverrides(a)
  RemoveAllReferenceSkinOverrides(a)
}

function MuscleDefTypeToTexStr(type: MuscleDefinitionType) {
  const mt = MuscleDefinitionType
  return type === mt.athletic
    ? "Fit"
    : type === mt.fat
    ? "Fat"
    : type === mt.custom1
    ? "Cs1"
    : type === mt.custom2
    ? "Cs2"
    : type === mt.custom3
    ? "Cs3"
    : "Meh"
}

/** Generates a normal texture path given some values.
 *
 * @param s Actor sex.
 * @param r Actor racial group.
 * @param type Actor muscle definition type. {@link MuscleDefinitionType}.
 * @param lvl Actor muscle definition level.
 * @returns A texture path that can be used to override normal maps.
 */
export function GetMuscleDefTex(
  s: Sex,
  r: RacialGroup,
  type: MuscleDefinitionType,
  lvl: number,
  Log: TappedFunction = LogIT
) {
  const ss = s === Sex.female ? "Fem" : "Man"
  const n = lvl.toString().padStart(2, "0")
  const mt = MuscleDefinitionType
  const t = MuscleDefTypeToTexStr(type)
  const rg = typeof r === "number" ? RacialGroup[r] : r

  return Log(
    "Applied muscle definition",
    `actors\\character\\Maxick\\${rg}\\${ss}${t}_${n}.dds`
  )
}

export const getMuscleDefTexName = (shortName: string) =>
  shortName === "" ? undefined : `actors\\character\\Maxick\\mdef\\${shortName}`

export const getSkinTexName = (shortName: string) =>
  shortName === "" ? undefined : `actors\\character\\Maxick\\skin\\${shortName}`

export function GetHeadSize(fitStage: FitStage, sex: Sex, w: number) {
  const lo = sex === Sex.female ? fitStage.femHeadLo : fitStage.manHeadLo
  const hi = sex === Sex.female ? fitStage.femHeadHi : fitStage.manHeadHi
  return InterpolateW(lo, hi, w)
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

/** Returns whether a race belongs to the banned races list.
 *
 * @param raceEDID Race Editor Id to check.
 * @returns `boolean`
 */
export function IsMuscleDefBanned(raceEDID: string) {
  const r = raceEDID.toLowerCase()
  const isBanned =
    muscleDefBanRace.filter((ban) => r.indexOf(ban) >= 0).length > 0
  if (isBanned) LogI("Can't change muscle definition. Race is banned.")
  return isBanned
}

export function IsFem(a: Actor) {
  const b = ActorBase.from(a.getLeveledActorBase())
  if (!b) return false
  return b.getSex() === Sex.female
}
