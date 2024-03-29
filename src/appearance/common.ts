import { LoggingFunction } from "DmLib/Log"
import { LinCurve } from "DmLib/Math"
import { Sex } from "../database"
import { LogI, LogN, LogV } from "../debug"
import { RaceGroup, TextureSignature, db } from "../types/exported"

/** Path to the files to be applied */
export interface TexturePaths {
  muscle?: string
  skin?: string
}

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
  /** Race EDID */
  race: RaceEDID
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

  if (result === undefined || result === null) {
    logNotFound(
      "was not found in exported data. Performing exhaustive search..."
    )
    const s = getSearched()
    if (s === null) memoizeNull()
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
    (desc) => LogV(`Race ${edid} ${desc}`)
  )

  const g = r.group
  LogV(`Race "${edid}" signature is "${g}"`)

  if (g == RaceGroup.Ban) {
    LogI("Can't continue because race is banned")
    return null
  } else if (g == RaceGroup.Unk) {
    LogI("Can't continue because race is unknown to this mod")
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
  LinCurve({ x: 0, y: y1 }, { x: 100, y: y2 })(x)

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

/** Gets texture paths for non-precalculated `Actors` */
export function getTextures(d: AppearanceData): TexturePaths {
  const fs = db.fitStages[d.fitstage.toString()]
  return textureIdsToPaths(d.muscleDef, fs.muscleDef, fs.skin, d.texSig, d.race)
}

export function textureIdsToPaths(
  muscleLvl: number | undefined,
  muscleType: number | undefined,
  skin: number | undefined,
  texSig: TextureSignature,
  race: RaceEDID
) {
  // Skin #1 is always the default skin. Won't override.
  const sk =
    skin === undefined ? undefined : skin === 1 ? "" : db.skin[skin - 2][texSig]

  const md =
    muscleType === undefined || muscleLvl === undefined
      ? undefined
      : db.muscleDef[muscleType - 1][texSig][muscleLvl - 1]

  const t = getTexturePaths(race, md, sk)

  LogI(`Muscle def texture: ${t.muscle}`)
  LogI(`Skin texture: ${t.skin}`)
  return t
}

export type ShortTextureName = string

const getTexName = (dir: string) => (shortName: ShortTextureName) =>
  shortName === ""
    ? undefined
    : `actors\\character\\Maxick\\${dir}\\${shortName}`

const getMuscleDefTexName = getTexName("mdef")
const getSkinTexName = getTexName("skin")

/** Determines if the race for an actor is banned from getting textures applied */
function isTextureBanned(edid: RaceEDID) {
  LogV("Is this Actor's race banned from getting textures?")

  const r = searchDirectAndByContent(
    () => db.texBanRace[edid],
    () => searchMapByContent(db.texBanRaceSearch, edid.toLowerCase()),
    (r) => (db.texBanRace[edid] = r),
    () => (db.texBanRace[edid] = false),
    (desc) => LogV(`Race ${edid} ${desc}`)
  )

  LogI(
    `Race is${r ? "" : " not"} banned. Textures ${
      r ? "won't" : "will"
    } be applied`
  )
  return r
}

/** Gets the texture paths that will be applied to an Actor. */
export function getTexturePaths(
  race: RaceEDID,
  muscle: ShortTextureName | undefined,
  skin: ShortTextureName | undefined
): TexturePaths {
  const ban = isTextureBanned(race)
  return {
    muscle:
      ban || muscle === undefined ? undefined : getMuscleDefTexName(muscle),
    skin: ban || skin === undefined ? undefined : getSkinTexName(skin),
  }
}

export function logBanner(
  message: string,
  log: LoggingFunction,
  separator: string = "="
) {
  const s = separator.repeat(message.length)
  log(s)
  log(message)
  log(s)
}
