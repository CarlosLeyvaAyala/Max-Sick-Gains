// Data exported from Max Sick Gains App
export type TextureSignature = "hm" | "hf" | "km" | "kf" | "am" | "af"
export const muscleDefMin = 1
export const muscleDefMax = 10
export const playerJourneyKey = "Player"

/** Whole data needed for the mod to function */
export interface MaxickDB {
  mcm: MCM
  /** Direct race solving */
  races: { [key: string]: Race }
  /** Race solving by string contents */
  raceSearch: { [key: string]: Race }
  muscleDef: MuscleDef[]
  skin: Skin[]
  fitStages: { [key: string]: FitStage }
  fitJourneys: FitJourneys
  archetypes: { [key: string]: Archetype }
  classArch: { [key: string]: number[] }
  classArchSearch: { [key: string]: number[] }
  raceArch: { [key: string]: number[] }
  raceArchSearch: { [key: string]: number[] }
  knownNPCs: KnownNPCS
  dynamicNPCs: DynamicNPCS
  texBanRace: TexBanRace
  texBanRaceSearch: TexBanRaceSearch
}

export interface Archetype {
  iName: string
  fitStage: number
  wLo: number
  wHi: number
  mDefLo: number
  mDefHi: number
  wReqLo: number
  wReqHi: number
}

export interface DynamicNPCS {
  [key: string]: { [key: string]: string }
}

export interface FitJourneys {
  [key: string]: FitJourney
}

/** Fitness Journey data */
export interface FitJourney {
  start: number
  totalDuration: number
  durations: number[]
  isFem: boolean
  stages: JourneyStage[]
}

export interface JourneyStage {
  fitStage: number
  isStart: boolean
  minDays: number
  welcomeMsg: string
  displayName: string
  bsLo: number
  bsHi: number
  muscleDefLo: number
  muscleDefHi: number
  blend: number
}

export interface FitStage {
  iName: string
  muscleDef: number
  skin: number
  fem: FitStageSexAppearance
  man: FitStageSexAppearance
}

export interface FitStageSexAppearance {
  bodyslide: { [key: string]: BSSlider }
  headLo: number
  headHi: number
}

export interface BSSlider {
  min: number
  max: number
}

export interface KnownNPCS {
  [key: string]: { [key: string]: KnownNPCData }
}

export interface KnownNPCData {
  name: string
  uniqueId: string
  muscleDef: string
  skin: string
  head: number
  bodyslide: { [key: string]: number }
}

export interface MCM {
  logging: Logging
  testingMode: TestingMode
  actors: Actors
  training: Training
  widget: Widget
}

export interface Actors {
  player: ActorAppearanceSettings
  men: ActorAppearanceSettings
  fem: ActorAppearanceSettings
  // knownMan: ActorAppearanceSettings
  // knownFem: ActorAppearanceSettings
  // genericMan: ActorAppearanceSettings
  // genericFem: ActorAppearanceSettings
  hkReset: string
  hkResetNearby: string
}

export interface ActorAppearanceSettings {
  applyMorphs: boolean
  applyMuscleDef: boolean
}

export interface Logging {
  level: number
  toFile: boolean
  toConsole: boolean
  anims: boolean
}

export interface TestingMode {
  enabled: boolean
  hkGainsAdd10: string
  hkGainsSub10: string
  hkNext: string
  hkPrev: string
  hkSlideshow: string
}

export interface Training {
  decayMin: number
  decayMax: number
}

export interface Widget {
  toggle: string
  meters: { [key: string]: Meter }
}

export interface Meter {
  x: number
  y: number
  w: number
  h: number
}

export interface MuscleDef {
  hm: string[]
  hf: string[]
  km: string[]
  kf: string[]
  am: string[]
  af: string[]
}

export interface Race {
  group: RaceGroup
  display: string
}

export enum RaceGroup {
  Arg = "Arg",
  Ban = "Ban",
  Hum = "Hum",
  Kha = "Kha",
  Unk = "Unk",
}

export interface Skin {
  hm: string
  hf: string
  km: string
  kf: string
  am: string
  af: string
}

export interface TexBanRace {
  [key: string]: boolean
}

export interface TexBanRaceSearch {
  [key: string]: boolean
}

import { settings } from "skyrimPlatform"

// TODO: Enable when ready
const modName = "maxick"
//@ts-ignore
export const db: MaxickDB = settings[modName]
// export let db: MaxickDB

// TODO: Delete
// import * as MiscUtil from "PapyrusUtil/MiscUtil"
// export function loadAlternateData() {
//   db = JSON.parse(MiscUtil.ReadFromFile("Data/SKSE/Plugins/Maxick/test.json"))
// }
