import { Actor } from "skyrimPlatform"
import { LogN } from "../../debug" // TODO: Change to proper log level
import { db } from "../../types/exported"
import {
  RaceEDID,
  searchDirectAndByContent,
  searchMapByContent,
} from "../common"
import { applySkin } from "./skin"
import { Sex } from "../../database"

/** Path to the files to be applied */
export interface TexturePaths {
  muscle?: string
  skin?: string
}

/** An already calculated Bodyslide preset. Ready to be applied to an `Actor`. */
export type BodyslidePreset = Map<string, number>

/** Complete ´Actor´ appearance: body morphs and head size */
export interface BodyShape {
  bodySlide: BodyslidePreset
  headSize: number
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
  LogN("Is this Actor's race banned from getting textures?")

  const r = searchDirectAndByContent(
    () => db.texBanRace[edid],
    () => searchMapByContent(db.texBanRaceSearch, edid.toLowerCase()),
    (r) => (db.texBanRace[edid] = r),
    () => (db.texBanRace[edid] = false),
    (desc) => LogN(`Race ${edid} ${desc}`)
  )

  LogN(
    `Race is${r ? "" : " not"} banned. Textures ${
      r ? "won't" : "will"
    } be applied`
  )
  return r
}

/** Gets the texture paths that will be applied to an Actor. */
export function getTexturePaths(
  race: RaceEDID,
  muscle: ShortTextureName,
  skin: ShortTextureName
): TexturePaths {
  LogN("************** getTexturePaths")
  const ban = isTextureBanned(race)
  return {
    muscle: ban ? undefined : getMuscleDefTexName(muscle),
    skin: ban ? undefined : getSkinTexName(skin),
  }
}

export function applyTextures(a: Actor, s: Sex, texs: TexturePaths) {
  applySkin(a, s, texs.skin)
}
