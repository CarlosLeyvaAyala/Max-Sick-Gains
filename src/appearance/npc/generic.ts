import { RaceGroup, db } from "../../types/exported"
import {
  AppearanceData,
  RaceEDID,
  raceSexToTexSignature,
  searchDirectAndByContent,
  searchMapByContent,
  weightInterpolation,
} from "../common"
import { LogN, LogV } from "../../debug" // TODO: Change to proper log level
import { CanApply, NPCData, NpcIdentity } from "./common"
import { isInRange } from "DmLib/Math/isInRange"
import { linCurve } from "DmLib/Math/linCurve"
import { intersection } from "DmLib/Set/intersection"
import { Sex } from "../../database"

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
  const a = db.archetypes[archetypeId?.toString() ?? "1"]
  const w = weightInterpolation(a.wLo, a.wHi, d.weight)

  return {
    fitstage: a.fitStage,
    muscleDef: Math.round(weightInterpolation(w, a.mDefLo, a.mDefHi)),
    texSig: raceSexToTexSignature(race, d.sex),
    sex: d.sex,
    weight: w,
  }
}
