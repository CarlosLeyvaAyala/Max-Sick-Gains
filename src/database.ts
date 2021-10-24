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

/**
 * Returns from database the Fitness Stage of some id.
 * @param id
 * @returns @see {@link FitStage}
 */
export function fitStage(id: number | string) {
  const i = typeof id === "number" ? id.toString() : id
  // @ts-ignore
  return fitStages[i] as FitStage
}
