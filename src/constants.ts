import { ActorValue } from "skyrimPlatform"
import { ClassArchetype } from "./database"

export const playerId = 0x14

export function ActorValueToStr(a: ActorValue): string {
  if (a === ActorValue.OneHanded) return "OneHanded"
  if (a === ActorValue.TwoHanded) return "TwoHanded"
  if (a === ActorValue.Archery) return "Archery"
  if (a === ActorValue.Block) return "Block"
  if (a === ActorValue.Smithing) return "Smithing"
  if (a === ActorValue.HeavyArmor) return "HeavyArmor"
  if (a === ActorValue.LightArmor) return "LightArmor"
  if (a === ActorValue.Pickpocket) return "Pickpocket"
  if (a === ActorValue.Lockpicking) return "Lockpicking"
  if (a === ActorValue.Sneak) return "Sneak"
  if (a === ActorValue.Alchemy) return "Alchemy"
  if (a === ActorValue.Speech) return "Speech"
  if (a === ActorValue.Alteration) return "Alteration"
  if (a === ActorValue.Conjuration) return "Conjuration"
  if (a === ActorValue.Destruction) return "Destruction"
  if (a === ActorValue.Illusion) return "Illusion"
  if (a === ActorValue.Restoration) return "Restoration"
  if (a === ActorValue.Enchanting) return "Enchanting"
  return ""
}

export const defaultArchetype: ClassArchetype = {
  iName: "Default",
  fitStage: 1,
  bsLo: 0,
  bsHi: 100,
  muscleDefLo: 1,
  muscleDefHi: 6,
  raceExclusive: [],
  weightLo: 0,
  weightHi: 100,
}
