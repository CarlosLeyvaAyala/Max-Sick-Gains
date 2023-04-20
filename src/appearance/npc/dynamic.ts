import * as JourneyCache from "../shared/cache/dynamic"
import * as Journeys from "../shared/dynamic/journey/manager"
import { db } from "../../types/exported"
import { ApplyAppearanceData } from "../shared/appearance"
import {
  AppCachedFormID,
  EspLower,
  NpcIdentity,
  getPreGenerated,
} from "./calculated"
import { ActorData } from "../shared/ActorData"

/** Gets the Journey id for a dynamic NPC */
export const getJourney = (esp: EspLower, id: AppCachedFormID) =>
  getPreGenerated(esp, id, db.dynamicNPCs)

/** Gets the ready to be applied appearance data for a Dynamic NPC */
export function getAppearanceData(
  formID: number,
  identity: NpcIdentity,
  d: ActorData
): ApplyAppearanceData | null {
  const jk = identity.journey as string
  const dynApp = Journeys.getAppearanceData(jk, identity.race, d.race, d.sex)
  if (!dynApp) return null

  return {
    bodyShape: dynApp.bodyShape,
    textures: dynApp.textures,
    saveToCache: () => JourneyCache.save(formID, jk, identity.race),
  }
}
