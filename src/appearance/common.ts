import { RaceGroup, db } from "../types/exported"
import { LogN } from "../debug" // TODO: Change to proper log level

/** EDID of a race */
export type RaceEDID = string
/** Lowercase race EDID */
type RaceEDIDLower = string

/** Searches a map for a string by content */
export function searchMapByContent<T>(
  map: { [key: string]: T },
  value: string
) {
  for (const key in map) if (value.indexOf(key) >= 0) return map[key]
  return null
}

/** Performs a direct search or a search by content.
 * @remarks
 * This function:
 * - Makes a direct search
 * - Makes a search by content if the direct search got nothing
 * - Memoizes the results of the search by content
 */
export function searchDirectAndByContent<T>(
  getPreGenerated: () => T,
  getSearched: () => T | null,
  memoizeFound: (v: T) => {},
  memoizeNull: () => {},
  logNotFound: (d: string) => void
) {
  const result = getPreGenerated()

  if (!result) {
    logNotFound(
      "was not found in exported data. Performing exhaustive search..."
    )
    const s = getSearched()
    if (!s) memoizeNull()
    else memoizeFound(s)
    return getPreGenerated() // Null data was added and now is among the pre-generated data
  }

  return result
}

/** Gets the race signature of an `Actor` */
export function getRaceSignature(edid: RaceEDID) {
  const r = searchDirectAndByContent(
    () => db.races[edid],
    () => searchMapByContent(db.raceSearch, edid.toLowerCase()),
    (r) => (db.races[edid] = r),
    () => (db.races[edid] = { display: edid, group: RaceGroup.Unk }),
    (desc) => LogN(`Race ${edid} ${desc}`)
  )

  const g = r.group
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
