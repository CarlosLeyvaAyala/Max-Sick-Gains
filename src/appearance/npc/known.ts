import { db } from "../../types/exported"
import { CachedFormID, EspLower, getPreGenerated } from "./calculated"

export const getKnownNPC = (esp: EspLower, id: CachedFormID) =>
  getPreGenerated(esp, id, db.knownNPCs)
