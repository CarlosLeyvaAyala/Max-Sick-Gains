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

/** Check which settings a solved NPC can get applied */
// export function canApplyChanges(d: NPCData, i: NpcIdentity): CanApply {
//   function toCanA(s: ActorAppearanceSettings): CanApply {
//     return { morphs: s.applyMorphs, textures: s.applyMuscleDef }
//   }

//   const settings = db.mcm.actors

//   switch (d.sex) {
//     case Sex.female:
//       switch (i.npcType) {
//         case NpcType.dynamic:
//         case NpcType.known:
//         case NpcType.cached:
//           return toCanA(settings.knownFem)
//         case NpcType.generic:
//           return toCanA(settings.genericFem)
//       }
//     case Sex.male:
//       switch (i.npcType) {
//         case NpcType.dynamic:
//         case NpcType.known:
//         case NpcType.cached:
//           return toCanA(settings.knownMan)
//         case NpcType.generic:
//           return toCanA(settings.genericMan)
//       }
//     default:
//       return { morphs: false, textures: false }
//   }
// }

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
