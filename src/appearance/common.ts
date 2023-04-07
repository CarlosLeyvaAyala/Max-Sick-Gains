import { printConsole } from "skyrimPlatform"
import { RaceGroup, db } from "../types/exported"
import { LogN } from "../debug" // TODO: Change to proper log level
import { Log } from "DmLib/Log/R"

/** EDID of a race */
export type RaceEDID = string
/** Lowercase race EDID */
type RaceEDIDLower = string

/** Searches a map for a string by content */
function searchMapByContent<T>(map: { [key: string]: T }, value: string) {
  for (const key in map) if (value.indexOf(key) >= 0) return map[key]
  return null
}

/** Searches the race database for an unknown race */
function searchRaceSig(edid: RaceEDIDLower) {
  return searchMapByContent(db.raceSearch, edid)
}

function logRaceSignatureResults(edid: RaceEDID) {
  return (g: RaceGroup) => {
    LogN(`Race "${edid}" signature is "${g}"`)

    if (g == RaceGroup.Ban) {
      LogN("Can't continue because race is banned")
      return null
    } else if (g == RaceGroup.Unk) {
      LogN("Can't continue because race is unknown to this mod")
      return null
    }
    return g
  }
}
/** Gets the race signature of an `Actor` */
export function getRaceSignature(edid: RaceEDID) {
  const LR = logRaceSignatureResults(edid)

  let r = db.races[edid]

  if (!r) {
    LogN(
      `Race ${edid} was not found in exported data. Doing exhaustive search.`
    )

    const s = searchRaceSig(edid.toLowerCase())
    // Memoize
    if (!s) db.races[edid] = { display: edid, group: RaceGroup.Unk }
    else db.races[edid] = s
    // Found data
    r = db.races[edid]
  }

  return LR(r.group)
}
