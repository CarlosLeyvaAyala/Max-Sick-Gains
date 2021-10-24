import { LinCurve } from "DM-Lib/Math"
import * as NiOverride from "Racemenu/nioverride"
import { Actor } from "skyrimPlatform"
import { FitStage, BsSlider } from "../database"
import { LogE, LogV } from "../debug"

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
function BlendBs(bs: object, w: number, warn: string): BodyslidePreset {
  const r = new Map()
  for (const slN in bs) {
    // @ts-ignore
    const sl = bs[slN] as BsSlider
    const v = LinCurve({ x: 0, y: sl.min }, { x: 100, y: sl.max })(w)
    r.set(slN, v)
  }

  if (r.size < 1) LogE(`Warning: ${warn} is empty`)

  return r
}

/**
 * Calculates how a woman Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the female preset from.
 * @param weight At which weight the preset will be calculated.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
export function BlendFemBs(
  fitStage: FitStage,
  weight: number
): BodyslidePreset {
  return BlendBs(
    fitStage.femBs,
    weight,
    `$female Bodyslide for Fitness Stage "${fitStage.iName}"`
  )
}

/**
 * Calculates how a man Bodyslide preset for some Fitness Stage should look at some given weight.
 *
 * @param fitStage The fitness stage object to get the male preset from.
 * @param weight At which weight the preset will be calculated.
 * @returns A {@link BodyslidePreset} with slider values corresponding to the input `weight`.
 */
export function BlendManBs(
  fitStage: FitStage,
  weight: number
): BodyslidePreset {
  return BlendBs(
    fitStage.manBs,
    weight,
    `$male Bodyslide for Fitness Stage "${fitStage.iName}"`
  )
}

const ClearMorphs = NiOverride.ClearMorphs

function MarkProcessed(a: Actor) {
  NiOverride.SetBodyMorph(a, "MaxickProcessed", "Maxick", 1)
}

export function ApplyBodyslide(a: Actor, bs: BodyslidePreset) {
  ClearMorphs(a)

  bs.forEach((v, sl) => {
    NiOverride.SetBodyMorph(a, sl, "Maxick", v / 100)
  })

  NiOverride.UpdateModelWeight(a)
  MarkProcessed(a) // Need to mark the actor again due to clearing bodyslides
}

export function ClearAppearance(a: Actor | null) {
  LogV("--- Clearing appearance")
  NiOverride.ClearMorphs(a)
  NiOverride.RemoveAllReferenceOverrides(a)
  NiOverride.RemoveAllReferenceSkinOverrides(a)
}
