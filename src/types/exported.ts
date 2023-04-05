// Data exported from Max Sick Gains App

export interface MaxickDB {
  mcm: MCM
  races: { [key: string]: Race }
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

/**  */
export interface FitJourney {
  start: number
  totalDuration: number
  durations: number[]
  stages: JourneyStage[]
}

export interface JourneyStage {
  fitStage: number
  isStart: boolean
  minDays: number
  welcomeMsg: string
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
  knownMan: ActorAppearanceSettings
  knownFem: ActorAppearanceSettings
  genericMan: ActorAppearanceSettings
  genericFem: ActorAppearanceSettings
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
  DA13AfflictedRace: string
  ElderRace: string
  ManakinRace: string
  NordRaceAstrid: string
  TeeenAfflictedRace: string
}

export interface TexBanRaceSearch {
  afflicted: string
  astrid: string
  elder: string
  manakin: string
}
