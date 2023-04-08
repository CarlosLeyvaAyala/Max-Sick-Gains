import { db } from "../../types/exported"
import {
  RaceEDID,
  searchDirectAndByContent,
  searchMapByContent,
} from "../common"
import { LogN, LogV } from "../../debug" // TODO: Change to proper log level
import { NPCData } from "./common"
import { isInRange } from "DmLib/Math/isInRange"
import { intersection } from "DmLib/Set/intersection"

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
  LogV(`Possible class archetypes: ${ca}`)
  const ra = getRaceArchetypes(d.race)
  LogV(`Possible race archetypes: ${ra}`)

  return _getArchetype(d.weight, ca, ra)
}

export function generateMorphs() {}
