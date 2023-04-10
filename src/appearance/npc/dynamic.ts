import { db } from "../../types/exported"
import { CachedFormID, EspLower, getPreGenerated } from "./calculated"

/** Gets the Journey id for a dynamic NPC */
export const getJourney = (esp: EspLower, id: CachedFormID) =>
  getPreGenerated(esp, id, db.dynamicNPCs)
