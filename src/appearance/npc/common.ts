import { Actor, ActorBase } from "skyrimPlatform"
import { RaceEDID } from "../common"
import { Sex } from "../../database"

/** Lowercase esp name. The configuration app exports this. */
export type EspLower = string
/** Form id as a string. The configuration app exports this.  */
export type CachedFormID = string

/** Data needed to solve an NPC appearance. */
export interface NPCData {
  /** The `Actor` data per se */
  actor: Actor
  /** The leveled `ActorBase` the NPC belongs to */
  base: ActorBase
  /** Male or female? */
  sex: Sex
  /** TES class. */
  class: string
  /** Esp file where the actor was defined */
  esp: string
  /** FormId of `base` inside its esp file */
  fixedFormId: number
  /** Full name of the NPC */
  name: string
  /** Race EDID for the NPC */
  race: RaceEDID
  /** NPC weight. [0..100] */
  weight: number
  /** Current in game formID. Used for caching. */
  formID: number
}

/** Gets the data from a pre-generated esp[id] map if it exists */
export function getPreGenerated<T>(
  esp: EspLower,
  id: CachedFormID,
  map: { [esp: string]: { [id: string]: T } }
) {
  const j = map[esp]
  if (!j) return null
  const target = j[id]
  if (!target) return null
  return target
}
