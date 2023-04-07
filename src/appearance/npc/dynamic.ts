import { db } from "../../types/exported"
import { CachedFormID, EspLower, getPreGenerated } from "./common"

export const getJourney = (esp: EspLower, id: CachedFormID) =>
  getPreGenerated(esp, id, db.dynamicNPCs)
