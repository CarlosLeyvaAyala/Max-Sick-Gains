import { db } from "../../types/exported"
import {
  RaceEDID,
  searchDirectAndByContent,
  searchMapByContent,
} from "../common"
import { LogN } from "../../debug" // TODO: Change to proper log level
import { NPCData } from "./common"

function getClassArchetypes(className: string) {
  const cn = className
  const r = searchDirectAndByContent(
    () => db.classArch[cn],
    () => searchMapByContent(db.classArchSearch, cn.toLowerCase()),
    (a) => (db.classArch[cn] = a),
    () => (db.classArch[cn] = []),
    (desc) => LogN(`Class ${desc}`)
  )
  return r
}

function getRaceArchetypes(race: RaceEDID) {
  const r = searchDirectAndByContent(
    () => db.raceArch[race],
    () => searchMapByContent(db.raceArchSearch, race.toLowerCase()),
    (a) => (db.raceArch[race] = a),
    () => (db.raceArch[race] = []),
    (desc) => LogN(`Race ${desc}`)
  )
  return r
}

function _getArchetype(classArchetypes: number[], raceArchetypes: number[]) {
  const setA = new Set(classArchetypes)
  const setB = new Set(raceArchetypes)

  // Set intersection
  for (const elem of setB) if (setA.has(elem)) return elem

  return null
}

export function getArchetype(d: NPCData) {
  LogN("Is a generic NPC")
  LogN(`Class: ${d.class}`)
  const ca = getClassArchetypes(d.class)
  LogN(`Possible class archetypes: ${ca}`)
  const ra = getRaceArchetypes(d.race)
  LogN(`Possible race archetypes: ${ra}`)
  return _getArchetype(ca, ra)
}
