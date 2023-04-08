import { Sex } from "../database"
import { linCurve } from "DmLib/Math/linCurve"
import { DebugLib as D } from "Dmlib"
import { LogE, LogI, LogIT, LogN, LogV, LogVT } from "../debug"
import { FitStage, FitStageSexAppearance, BSSlider } from "../types/exported"
import { AppearanceData, weightInterpolation } from "./common"
import { db } from "../types/exported"

/** An already calculated Bodyslide preset. Ready to be applied to an `Actor`. */
export type BodyslidePreset = Map<string, number>

/** Total ´Actor´ shape appearance: body morphs and head size */
export interface BodyShape {
  bodySlide: BodyslidePreset
  headSize: number
}

export function getBodyShape(
  d: AppearanceData,
  Morph: BsCalc = stdMorph,
  Log: D.Log.LoggingFunction = LogN
): BodyShape {
  const fs = db.fitStages[d.fitstage.toString()]
  const app = d.sex == Sex.male ? fs.man : fs.fem

  Log(`Getting body shape from Fitness Stage: ${fs.iName}`)

  return {
    bodySlide: blendBs(app, d.weight, Morph),
    headSize: weightInterpolation(d.weight, app.headLo, app.headHi),
  }
}

/**  Returns a fully calculated Bodyslide preset for some Fitness Stage, sex and weight.
 *
 * @param fs Fitness Stage.
 * @param s Sex.
 * @param w Weight. [`0..100`].
 * @param Morph Interpolation function. This is used to calculate individual sliders.
 * @returns Fully calculated Bodyslide preset. Ready to be applied to an `Actor`.
 */
function getBodyslide(
  app: FitStageSexAppearance,
  s: Sex,
  w: number,
  Morph: BsCalc = stdMorph,
  Log: D.Log.LoggingFunction = LogV
): BodyslidePreset {
  // Log(`Fitness Stage Bodyslide preset applied: ${fs.iName}`)
  return blendBs(app, w, Morph)
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
  linCurve({ x: 0, y: min }, { x: 100, y: max })(w)

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
function blendBs(
  bs: FitStageSexAppearance,
  w: number,
  Morph: BsCalc
): BodyslidePreset {
  const r = new Map()

  for (const [slN, sl] of Object.entries(bs.bodyslide)) {
    const v = Morph(sl.min, sl.max, w) / 100
    r.set(slN, v)
  }

  return r
}
