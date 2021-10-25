import { LinCurve } from "DM-Lib/Math"
import {
  ClearMorphs,
  RemoveAllReferenceOverrides,
  RemoveAllReferenceSkinOverrides,
  SetBodyMorph,
  UpdateModelWeight,
} from "Racemenu/nioverride"
import { Actor } from "skyrimPlatform"
import { FitStage, BsSlider, Sex } from "../database"
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

export function ClearAppearance(a: Actor | null) {
  ClearMorphs(a)
  RemoveAllReferenceOverrides(a)
  RemoveAllReferenceSkinOverrides(a)
}
