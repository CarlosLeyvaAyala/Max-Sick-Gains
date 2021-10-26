// @ts-nocheck
import { settings } from "skyrimPlatform"

/** How many types of muscle definition there are.
 * @remarks
 * Which type of normal texture gets applied to an `Actor` depends on this.
 */
export enum MuscleDefinitionType {
  plain = 0,
  athletic,
  fat,
}

export enum Sex {
  male = 0,
  female,
  undefined,
}

/** Raw slider data as read from the settings file. */
export interface BsSlider {
  /** Min slider value. */
  min: number
  /** Max slider value. */
  max: number
}

/** Fitness stage data. */
export interface FitStage {
  /** Internal name for this fitness stage. Mostly used for debugging. */
  iName: string
  /** @see {@link MuscleDefinitionType} */
  muscleDefType: MuscleDefinitionType
  /** Raw Bodyslide preset whose keys are Slider names and values are {@link BsSlider} */
  femBs: object
  /** Raw Bodyslide preset whose keys are Slider names and values are {@link BsSlider} */
  manBs: object
}

const modName = "maxick"
const fitStages = settings[modName]["fitStages"]
const classes = settings[modName]["classes"]

/**
 * Returns from database the Fitness Stage of some id.
 * @param id
 * @returns @see {@link FitStage}
 */
export function fitStage(id: number | string) {
  const i = typeof id === "number" ? id.toString() : id
  return fitStages[i] as FitStage
}

/**
 * Retuns all Class Archetype ids a Class belongs to.
 * @remarks
 * Class solving is done on both the Full Name and Class Name of an NPC.
 *
 * @param name NPC name.
 * @param aClass NPC class.
 * @returns Array of Class Archetypes.
 *
 * @example
 * const archs1 = ClassMatch("Whiterun Guard", "Guard")
 * const archs2 = ClassMatch("Legate Rikke", "Warrior")
 */
export function ClassMatch(name: string, aClass: string) {
  const n = name.toLowerCase()
  const c = aClass.toLowerCase()
  const r = []
  for (const key in classes)
    if (n.indexOf(key) >= 0 || c.indexOf(key) >= 0) r.push(classes[key])
  // Flatten and sort array
  const flat = ([] as number[]).concat(...r).sort((a, b) => a - b)
  // Avoid repeated elements
  return [...new Set(flat)]
}
