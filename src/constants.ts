import { ActorValue, Game, Spell } from "skyrimPlatform"
import { ClassArchetype } from "./database"

export const playerId = 0x14

export const modName = "Maxick"
export const animLog = `${modName}-Animations`

export const maxickEsp = "Max Sick Gains.esp"
export const maxickSpell = 0x96d
export const maxickSpellFx = 0x96c

export const MaxickSpell = () =>
  Spell.from(Game.getFormFromFile(maxickSpell, "Max Sick Gains.esp"))
export const MaxickSpellFx = () =>
  Game.getFormFromFile(maxickSpellFx, maxickEsp)

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
