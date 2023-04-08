import { Actor, ActorBase } from "skyrimPlatform"
import { RaceEDID } from "../common"
import { Sex } from "../../database"
import { ActorAppearanceSettings, KnownNPCData, db } from "../../types/exported"

/** Lowercase esp name. The configuration app exports this. */
export type EspLower = string
/** Form id as a string. The configuration app exports this.  */
export type CachedFormID = string

/** Types of NPCs available */
export enum NpcType {
  /** Has a Fitness Journey */
  dynamic,
  /** Data was fully known when the config file was generated */
  known,
  /** NPCs that fall into Archetypes */
  generic,
}

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

/** Data obtained while solving NPC identity */
export interface NpcIdentity {
  npcType: NpcType
  journey?: string
  knownData?: KnownNPCData
  archetype?: number
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

export interface CanApply {
  morphs: boolean
  textures: boolean
}

/** Check which settings a solved NPC can get applied */
export function canApplyChanges(d: NPCData, i: NpcIdentity): CanApply {
  function toCanA(s: ActorAppearanceSettings): CanApply {
    return { morphs: s.applyMorphs, textures: s.applyMuscleDef }
  }

  const settings = db.mcm.actors

  switch (d.sex) {
    case Sex.female:
      switch (i.npcType) {
        case NpcType.dynamic:
        case NpcType.known:
          return toCanA(settings.knownFem)
        case NpcType.generic:
          return toCanA(settings.genericFem)
      }
    case Sex.male:
      switch (i.npcType) {
        case NpcType.dynamic:
        case NpcType.known:
          return toCanA(settings.knownMan)
        case NpcType.generic:
          return toCanA(settings.genericMan)
      }
    default:
      return { morphs: false, textures: false }
  }
}
