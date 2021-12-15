// @ts-nocheck
import { settings } from "skyrimPlatform"

/** How many types of muscle definition there are.
 * @remarks
 * Which type of normal texture gets applied to an `Actor` depends on this.
 */
export enum MuscleDefinitionType {
  /** Not fat nor ripped textures. */
  plain = 0,
  /** Ripped textures. */
  athletic,
  /** Fat textures. */
  fat,
}

export enum RacialGroup {
  /** Banned. */
  Ban = 0,
  /** Humanoid. */
  Hum,
  /** Khajiit. */
  Kha,
  /** Argonian. */
  Arg,
}

/** Data needed to change muscle definition to an `Actor`. */
export interface MuscleDefinition {
  /** What type of muscle definition the `Actor` has. */
  type: MuscleDefinitionType
  /** What muscle definition level will be applied. No definition will be applied if `undefined`. */
  level: number
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
  /** Lower head size. */
  femHeadLo: number
  /** Higher head size. */
  femHeadHi: number
  /** Lower head size. */
  manHeadLo: number
  /** Higher head size. */
  manHeadHi: number
}

export interface ClassArchetype {
  iName: string
  fitStage: number
  bsLo: number
  bsHi: number
  muscleDefLo: number
  muscleDefHi: number
  raceExclusive: string[]
}

export interface KnownNpcData {
  fullName: string
  fitStage: number
  weight: number
  muscleDef: number
}

export interface PlayerStage {
  fitStage: number
  minDays: number
  displayName: string
  bsLo: number
  bsHi: number
  muscleDefLo: number
  muscleDefHi: number
  headLo: number
  headHi: number
  blend: number
}

export interface TestingMode {
  enabled: boolean
  next?: number
}

// "MCM": {"testingMode": {"enabled": true}},
export interface McmOptions {
  testingMode: TestingMode
}

const modName = "maxick"
const fitStages = settings[modName]["fitStages"]
const classes = settings[modName]["classes"]
const archetypes = settings[modName]["classArchetypes"]
const races = settings[modName]["races"]
export const knownNPCs: object = settings[modName]["knownNPCs"]
export const muscleDefBanRace: string[] = settings[modName]["muscleDefBanRace"]
export const playerStages: PlayerStage[] = settings[modName]["playerStages"]
export const MCM: McmOptions = settings[modName]["MCM"]

// const fitStages: object
// const classes: object
// const archetypes: object
// const races: object
// export const knownNPCs: object
// export const muscleDefBanRace: string[]
// export const playerStages: PlayerStage[]

/** Returns from database the Fitness Stage of some id.
 * @param id
 * @returns @see {@link FitStage}
 */
export function fitStage(id: number | string) {
  const i = typeof id === "number" ? id.toString() : id
  return fitStages[i] as FitStage
}

/** Retuns all Class Archetype ids a Class belongs to.
 * @remarks
 * Class solving is done on both the Full Name and Class Name of an NPC.
 *
 * @param name NPC name.
 * @param aClass NPC class.
 * @returns Array of Class Archetype ids.
 *
 * @example
 * const archs1 = ClassMatch("Whiterun Guard", "Guard")
 * const archs2 = ClassMatch("Legate Rikke", "Warrior")
 */
export function ClassMatch(name: string, aClass: string): number[] {
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

export function classArchetype(id: number | string) {
  const i = typeof id === "number" ? id.toString() : id
  return archetypes[i] as ClassArchetype
}

/** Gets which racial group a race belongs to. */
export function RacialMatch(raceEDID: string): RacialGroup | null {
  const race = raceEDID.toLowerCase()
  for (const key in races)
    if (race.indexOf(key) >= 0) return RacialGroup[races[key].group]
  return null
}
