// @ts-nocheck1
import { DebugLib } from "Dmlib"
import { printConsole, settings } from "skyrimPlatform"

/** Json object that contains all data read from settings.txt. */
export interface MaxickSettings {
  MCM: McmOptions
  races: { [key: string]: RaceData }
  fitStages: { [key: string]: FitStage }
  playerStages: PlayerStage[]
  classArchetypes: { [key: string]: ClassArchetype }
  classes: { [key: string]: number[] }
  knownNPCs: { [key: string]: { [key: string]: KnownNpcData } }
  muscleDefBanRace: string[]
}

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

/** Data needed to change muscle definition to an `Actor`. */
export interface MuscleDefinition {
  /** What type of muscle definition the `Actor` has. */
  type: MuscleDefinitionType
  /** What muscle definition level will be applied. No definition will be applied if `undefined`. */
  level: number
}

/** `Actor` sex. */
export enum Sex {
  male = 0,
  female,
  undefined,
}

export interface McmOptions {
  testingMode: TestingMode
  logging: Logging
  actors: ActorsCfg
}

export interface ActorsCfg {
  player: ActorOptions
  knownFem: ActorOptions
  knownMan: ActorOptions
  genericFem: ActorOptions
  genericMan: ActorOptions
}

export interface ActorOptions {
  applyMorphs: boolean
  applyMuscleDef: boolean
}

export interface Logging {
  /** As read directly from settings. */
  level: number
  /** Loging level actually used inside this mod. */
  lvl: DebugLib.Log.Level
  toConsole: boolean
  toFile: boolean
}

export interface TestingMode {
  enabled: boolean
  next?: number
}

export interface ClassArchetype {
  iName: string
  fitStage: number
  bsLo: number
  bsHi: number
  muscleDefLo: number
  muscleDefHi: number
  weightLo: number
  weightHi: number
  raceExclusive: string[]
}

/** Fitness stage data. */
export interface FitStage {
  /** Internal name for this fitness stage. Mostly used for debugging. */
  iName: string
  /** @see {@link MuscleDefinitionType} */
  muscleDefType: MuscleDefinitionType
  /** Lower head size. */
  femHeadLo: number
  /** Higher head size. */
  femHeadHi: number
  /** Lower head size. */
  manHeadLo: number
  /** Higher head size. */
  manHeadHi: number
  /** Raw Bodyslide preset whose keys are Slider names and values are {@link BsSlider} */
  femBs: { [key: string]: BsSlider }
  /** Raw Bodyslide preset whose keys are Slider names and values are {@link BsSlider} */
  manBs: { [key: string]: BsSlider }
}

/** Raw slider data as read from the settings file. */
export interface BsSlider {
  /** Min slider value. */
  min: number
  /** Max slider value. */
  max: number
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
  blend: number
}

export interface RaceData {
  group: RacialGroup
  display: string
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

const modName = "maxick"
//@ts-ignore
export const maxickSettings: MaxickSettings = settings[modName]
const ms = maxickSettings
export const knownNPCs = ms.knownNPCs
export const muscleDefBanRace = ms.muscleDefBanRace
export const playerStages = ms.playerStages
export const mcm = ms.MCM
mcm.logging.lvl = DebugLib.Log.LevelFromValue(mcm.logging.level)

/** Returns from database the Fitness Stage of some id.
 * @param id
 * @returns @see {@link FitStage}
 */
export function fitStage(id: number | string) {
  const i = typeof id === "number" ? id.toString() : id
  return ms.fitStages[i] as FitStage
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
  const classes = ms.classes
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

/** Returns the {@link ClassArchetype} at index `id`.
 * @param  {number|string} id
 * @returns ClassArchetype
 */
export function classArchetype(id: number | string): ClassArchetype {
  const i = typeof id === "number" ? id.toString() : id
  return ms.classArchetypes[i]
}

/** Gets which {@link RacialGroup} a race belongs to.
 * @param  {string} raceEDID Editor id of some race.
 * @returns RacialGroup
 */
export function RacialMatch(raceEDID: string): RacialGroup | null {
  const race = raceEDID.toLowerCase()
  for (const key in ms.races)
    if (race.indexOf(key) >= 0) return ms.races[key].group
  return null
}
