import { LinCurve } from "DM-Lib/Math"
import {
  AddNodeOverrideString,
  AddSkinOverrideString,
  ClearMorphs,
  Key,
  RemoveAllReferenceOverrides,
  RemoveAllReferenceSkinOverrides,
  SetBodyMorph,
  TextureIndex as Idx,
  UpdateModelWeight,
} from "Racemenu/nioverride"
import { Actor, Armor, Game, NetImmerse, SlotMask } from "skyrimPlatform"
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
    // const v = LinCurve({ x: 0, y: sl.min }, { x: 100, y: sl.max })(w)
    r.set(slN, v)
    // r.set(slN, v / 100)
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
  Morph: BsCalc = StdMorph
): BodyslidePreset {
  LogV(`Fitness stage applied: ${fs.iName}`)
  return s === Sex.male ? BlendManBs(fs, w, Morph) : BlendFemBs(fs, w, Morph)
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
  if (!path) {
    a.unequipItem(PizzaFix(), true, true)
    return
  }

  EquipPizzaHandsFix(a)
  const fem = s === Sex.female
  const t = Key.Texture
  const n = Idx.Normal
  const body = SlotMask.Body
  AddSkinOverrideString(a, fem, false, body, t, n, path, true)
  AddSkinOverrideString(a, fem, true, body, t, n, path, true)
  FixGenitalTextures(a)
}

const PizzaFix = () => Game.getFormFromFile(0x9dc, "Max Sick Gains.esp")

export function EquipPizzaHandsFix(a: Actor) {
  if (Armor.from(a.getWornForm(SlotMask.Hands))) return
  LogV("No gauntlets equipped. Solving the Pizza Hands Syndrome.")
  a.equipItem(PizzaFix(), false, true)
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

/** Fixes messed up anus and vagina textures.
 * @remarks
 * Setting normal maps messes with vagina and anus textures because they are technically part of the skin.
 * This function sets back the textures that should be there.
 *
 * @param a Actor to fix textures for.
 */
export function FixGenitalTextures(a: Actor) {
  Fix3BAGenitals(a)
}

function Fix3BAGenitals(a: Actor) {
  const b = "data\\textures\\actors\\character\\female\\femalebody_etc_v2_1"
  const d = b + ".dds"
  const n = b + "_msn.dds"
  const sk = b + "_sk.dds"
  const s = b + "_s.dds"
  NodeOverride(a, true, "3BA_Vagina", d, n, sk, s)
  NodeOverride(a, true, "3BA_Anus", d, n, sk, s)
  NodeOverride(a, true, "3BBB_Vagina", d, n, sk, s)
  NodeOverride(a, true, "3BBB_Anus", d, n, sk, s)
}

/** Temporarily overrides a node with 4 textures.
 *
 * @param a Actor.
 * @param isFem Is female?
 * @param node Node to override.
 * @param d Texture path.
 * @param n Texture path.
 * @param sk Texture path.
 * @param s Texture path.
 */
function NodeOverride(
  a: Actor,
  isFem: boolean,
  node: string,
  d: string,
  n: string,
  sk: string,
  s: string
) {
  if (!NetImmerse.hasNode(a, node, false)) return

  LogV(`Fixing genital node textures: ${node}`)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Diffuse, d, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Normal, n, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Skin, sk, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Specular, s, false)
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

/** Returns wether a race belongs to the banned races list.
 *
 * @param raceEDID Race Editor Id to check.
 * @returns `boolean`
 */
export function IsMuscleDefBanned(raceEDID: string) {
  const r = raceEDID.toLowerCase()
  const isBanned =
    muscleDefBanRace.filter((ban, _, __) => r.indexOf(ban) >= 0).length > 0
  if (isBanned) LogI("Can't change muscle definition. Race is banned.")
  return isBanned
}
