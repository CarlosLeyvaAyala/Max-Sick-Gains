import { db } from "../../types/exported"
import { AppCachedFormID, EspLower, getPreGenerated } from "./calculated"

export const getKnownNPC = (esp: EspLower, id: AppCachedFormID) =>
  getPreGenerated(esp, id, db.knownNPCs)
