import { LogI } from "../../debug"
import { db } from "../../types/exported"
import { BodyShape, exportedBstoPreset } from "../bodyslide"
import { getTexturePaths } from "../common"
import { ActorData } from "../shared/ActorData"
import { ApplyAppearanceData } from "../shared/appearance"
import { saveToCache } from "../shared/cache/non_dynamic"
import {
  AppCachedFormID,
  EspLower,
  NpcIdentity,
  getPreGenerated,
} from "./calculated"

/** Gets Known NPC data from exported database */
export const get = (esp: EspLower, id: AppCachedFormID) =>
  getPreGenerated(esp, id, db.knownNPCs)

/** Gets the ready to be applied appearance data for a Known NPC */
export function getAppearanceData(
  formID: number,
  identity: NpcIdentity,
  d: ActorData
): ApplyAppearanceData | null {
  const knData = identity.knownData
  if (!knData) return null

  LogI(
    `${knData.name} data was already calculated when exporting. Check the configuration app report for more info.`
  )

  const knShape: BodyShape = {
    bodySlide: exportedBstoPreset(knData.bodyslide),
    headSize: knData.head,
  }

  const ts = getTexturePaths(d.race, knData.muscleDef, knData.skin)

  return {
    bodyShape: { bodySlide: knShape.bodySlide, headSize: knData.head },
    textures: ts,
    saveToCache: () => saveToCache(formID, knShape, ts),
  }
}
