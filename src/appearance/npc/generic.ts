import { isInRange } from "DmLib/Math"
import { intersection } from "DmLib/Set"
import { LogI, LogN, LogV, LogVT } from "../../debug" // TODO: Change to proper log level
import { RaceGroup, db, muscleDefMax, muscleDefMin } from "../../types/exported"
import {
  AppearanceData,
  RaceEDID,
  raceSexToTexSignature,
  searchDirectAndByContent,
  searchMapByContent,
  weightInterpolation,
} from "../common"
import { ActorData } from "../shared/ActorData"

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
export function getArchetype(d: ActorData) {
  LogI("Is a generic NPC")
  const ca = LogVT("Possible class archetypes", getClassArchetypes(d.class))
  const ra = LogVT("Possible race archetypes", getRaceArchetypes(d.race))

  return _getArchetype(d.weight, ca, ra)
}

/** Gets the common appearance data for a generic NPC. */
export function getAppearanceData(
  d: ActorData,
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
