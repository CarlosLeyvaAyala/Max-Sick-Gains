import { I } from "DmLib/Combinators"
import { LoggingFunction } from "DmLib/Log"
import { LinCurve } from "DmLib/Math"
import { Sex } from "../database"
import { LogN } from "../debug"
import { FitStageSexAppearance, db } from "../types/exported"
import { AppearanceData, weightInterpolation } from "./common"

/** An already calculated Bodyslide preset. Ready to be applied to an `Actor`. */
export type BodyslidePreset = Map<string, number>

/** Complete ´Actor´ shape appearance: body morphs and head size */
export interface BodyShape {
  bodySlide: BodyslidePreset
  headSize: number
}

export function getBodyShape(
  d: AppearanceData,
  Morph: BsCalc = stdMorph,
  Log: LoggingFunction = LogN
): BodyShape {
  const fs = db.fitStages[d.fitstage.toString()]
  const app = d.sex == Sex.male ? fs.man : fs.fem

  Log(`Getting body shape from Fitness Stage: ${fs.iName}`)
  LogN(`Weight: ${d.weight}`)

  return {
    bodySlide: blendBs(app, d.weight, Morph),
    headSize: weightInterpolation(d.weight, app.headLo, app.headHi),
  }
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
const stdMorph: BsCalc = (min, max, w) =>
  LinCurve({ x: 0, y: min }, { x: 100, y: max })(w)

/** Morph with blending capabilities */
export const blendMorph =
  (blend: number) => (min: number, max: number, w: number) =>
    stdMorph(min, max, w) * blend

/** Calculates how a Bodyslide preset should look at some given weight.
 *
 * @param bs A raw Bodyslide preset
 * @param w At which weight the preset will be calculated.
 * @param Morph Interpolation function.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
const blendBs = (bs: FitStageSexAppearance, w: number, Morph: BsCalc) =>
  objToBsPreset(bs.bodyslide, (sl) => Morph(sl.min, sl.max, w))

/**Converts a pre-calculated Bodyslide to data that can be applied by this mod.  */
export const exportedBstoPreset = (bs: { [key: string]: number }) =>
  objToBsPreset(bs, I)

/** Converts an object with keys to a Bodyslide preset that can be applied by this mod. */
function objToBsPreset<T>(
  bs: { [key: string]: T },
  mapping: (v: T) => number
): BodyslidePreset {
  const r = new Map()

  for (const [slN, sl] of Object.entries(bs)) {
    r.set(slN, mapping(sl))
  }

  return r
}
