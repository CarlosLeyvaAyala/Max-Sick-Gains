import { isInRange } from "DmLib/Math"
import { intersection } from "DmLib/Set"
import { LogN } from "../../debug" // TODO: Change to proper log level
import { RaceGroup, db, muscleDefMax, muscleDefMin } from "../../types/exported"
import {
  AppearanceData,
  RaceEDID,
  TexturePaths,
  raceSexToTexSignature,
  searchDirectAndByContent,
  searchMapByContent,
  weightInterpolation,
} from "../common"
import { NPCData } from "./calculated"
import {
  Now,
  SkyrimHours,
  ToSkyrimHours,
  hourSpan,
  toSkyrimHours,
} from "DmLib/Time"
import { BodyShape } from "../bodyslide"

function getClassArchetypes(className: string) {
  const cn = className
  const r = searchDirectAndByContent(
    () => db.classArch[cn],
    () => searchMapByContent(db.classArchSearch, cn.toLowerCase()), // TODO: Fallback to all classes
    (a) => (db.classArch[cn] = a),
    () => (db.classArch[cn] = []),
    (desc) => LogN(`Class ${desc}`)
  )
  return r
}

function getRaceArchetypes(race: RaceEDID) {
  const r = searchDirectAndByContent(
    () => db.raceArch[race],
    () => searchMapByContent(db.raceArchSearch, race.toLowerCase()), // TODO: Fallback to all races
    (a) => (db.raceArch[race] = a),
    () => (db.raceArch[race] = []),
    (desc) => LogN(`Race ${desc}`)
  )
  return r
}

function _getArchetype(
  weight: number,
  classArchetypes: number[],
  raceArchetypes: number[]
) {
  const setA = new Set(classArchetypes)
  const setB = new Set(raceArchetypes)

  const possibleArchetypes = intersection(setA, setB)

  for (const archId of possibleArchetypes) {
    const a = db.archetypes[archId.toString()]

    if (isInRange(weight, a.wReqLo, a.wReqHi)) return archId
  }

  return undefined
}

/** Gets the Archetype id of the NPC */
export function getArchetype(d: NPCData) {
  LogN("Is a generic NPC")
  const ca = getClassArchetypes(d.class)
  LogN(`Possible class archetypes: ${ca}`)
  const ra = getRaceArchetypes(d.race)
  LogN(`Possible race archetypes: ${ra}`)

  return _getArchetype(d.weight, ca, ra)
}

/** Gets the common appearance data for a generic NPC. */
export function getAppearanceData(
  d: NPCData,
  race: RaceGroup,
  archetypeId: number | undefined
): AppearanceData {
  const a =
    archetypeId === undefined ? null : db.archetypes[archetypeId.toString()]
  const fs = a?.fitStage ?? 1
  const w = weightInterpolation(a?.wLo ?? 0, a?.wHi ?? 100, d.weight)

  return {
    fitstage: fs,
    muscleDef: Math.round(
      weightInterpolation(
        w,
        a?.mDefLo ?? muscleDefMin,
        a?.mDefHi ?? muscleDefMax
      )
    ),
    texSig: raceSexToTexSignature(race, d.sex),
    sex: d.sex,
    race: d.race,
    weight: w,
  }
}

interface CachedData {
  /** Last time the Actor was seen by this mod. */
  lastSeen: SkyrimHours
  /** Shape to apply. */
  shape: BodyShape
  /** Textures to apply. */
  textures: TexturePaths
}

/** Form id of the `Actor` instance; not their base ID. */
export type CachedFormID = number

type Cache = Map<CachedFormID, CachedData>
const cache: Cache = new Map()

/** Caches a generic NPC so its appearance calculation can be skipped */
export function saveToCache(
  formID: CachedFormID,
  shape: BodyShape,
  textures: TexturePaths
) {
  cache.set(formID, { lastSeen: Now(), shape: shape, textures: textures })
}

/** Gets the cached data if it exists */
export function getCached(
  formID: CachedFormID
): { shape: BodyShape; textures: TexturePaths } | null {
  const timeLimit = 24
  const d = cache.get(formID)
  if (!d) return null
  if (hourSpan(d.lastSeen) > timeLimit) return null // Actor may have already been recycled

  LogN("Actor was cached. Getting appearance from cache.")
  return { shape: d.shape, textures: d.textures }
}
