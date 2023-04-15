import { db } from "../../types/exported"
import { AppCachedFormID, EspLower, getPreGenerated } from "./calculated"

/** Gets the Journey id for a dynamic NPC */
export const getJourney = (esp: EspLower, id: AppCachedFormID) =>
  getPreGenerated(esp, id, db.dynamicNPCs)
