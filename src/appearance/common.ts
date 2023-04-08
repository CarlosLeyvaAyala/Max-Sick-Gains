import { RaceGroup, TextureSignature, db } from "../types/exported"
import { LogN } from "../debug" // TODO: Change to proper log level
import { Sex } from "../database"
import { linCurve } from "DmLib/Math/linCurve"

/** EDID of a race */
export type RaceEDID = string
/** Lowercase race EDID */
type RaceEDIDLower = string

/** Common data used to set a non-precalculated Actor appearance */
export interface AppearanceData {
  /** Fitness Stage */
  fitstage: number
  /** Weight that will be ultimately applied */
  weight: number
  /** Muscle definition level */
  muscleDef: number
  /** `Actor` sex */
  sex: Sex
  /** Signature used to set muscle definition and skin textures */
  texSig: TextureSignature
}

/** Body morphs */
export interface Morphs {
  headSize: number
}

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

/** Interpolates a value based on possible weight ranges.
 *
 * @param x Value to interpolate.
 * @param y1 `y` for `x = 0`
 * @param y2 `y` for `x = 100`
 * @returns Interpolated value.
 */
export const weightInterpolation = (x: number, y1: number, y2: number) =>
  linCurve({ x: 0, y: y1 }, { x: 100, y: y2 })(x)

/** Gets the Texture signature given a racial signature and sex */
export function raceSexToTexSignature(
  race: RaceGroup,
  sex: Sex
): TextureSignature {
  switch (race) {
    case RaceGroup.Hum:
      switch (sex) {
        case Sex.male:
          return "hm"
        default:
          return "hf"
      }
    case RaceGroup.Kha:
      switch (sex) {
        case Sex.male:
          return "km"
        default:
          return "kf"
      }
    default:
      switch (sex) {
        case Sex.male:
          return "am"
        default:
          return "af"
      }
  }
}

/** Gets the body shape for non-precalculated `Actors` */
export function getBodyShape(d: AppearanceData) {}

import { TexturePaths, getMuscleDefTexName, getSkinTexName } from "./appearance"

export function getTextures(d: AppearanceData): TexturePaths {
  const fs = db.fitStages[d.fitstage.toString()]

  // Skin #1 is always the default skin. Won't override.
  const sk =
    fs.skin === 1 ? undefined : getSkinTexName(db.skin[fs.skin - 2][d.texSig])
  const md = getMuscleDefTexName(
    db.muscleDef[fs.muscleDef - 1][d.texSig][d.muscleDef - 1]
  )

  LogN(`Muscle lvl: ${d.muscleDef}`)
  LogN(`Texture signature: ${d.texSig}`)
  LogN(`Muscle def texture: ${md}`)
  LogN(`Skin texture: ${sk}`)
  return { skin: sk, muscle: md }
}
