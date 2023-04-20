import { KnownNPCData, RaceGroup } from "../../types/exported"

/** Types of NPCs available */
export enum NpcType {
  /** Has a Fitness Journey */
  dynamic,
  /** Data was fully known when the config file was generated */
  known,
  /** NPCs that fall into Archetypes */
  generic,
  /** Non-dynamic cached NPCs. Cache is made by RefID */
  cached,
}

/** Data obtained while solving NPC identity */
export interface NpcIdentity {
  npcType: NpcType
  race: RaceGroup
  journey?: string
  knownData?: KnownNPCData
  archetype?: number
}

export interface CanApply {
  morphs: boolean
  textures: boolean
}

// TODO: Move everything below to common.ts
/** Lowercase esp name. The configuration app exports this. */
export type EspLower = string
/** Form id as a string. The configuration app exports this.  */
export type AppCachedFormID = string

/** Gets the data from a pre-generated esp[id] map if it exists */
export function getPreGenerated<T>(
  esp: EspLower,
  id: AppCachedFormID,
  map: { [esp: string]: { [id: string]: T } }
) {
  const j = map[esp]
  if (!j) return null
  const target = j[id]
  if (!target) return null
  return target
}
