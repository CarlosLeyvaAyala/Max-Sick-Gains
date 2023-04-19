import { Now } from "DmLib/Time"
import { Maybe } from "Maybe"
import { Sex } from "../../../database"
import { RaceGroup } from "../../../types/exported"
import { RecyclableActor, RefID, get as getCache } from "./_lastSeen"
import { JourneyKey } from "./journey"

export interface CachedNPC extends RecyclableActor {
  key: JourneyKey
  raceGroup: RaceGroup
}

type Cache = Map<RefID, CachedNPC>
const cache: Cache = new Map()

/** Caches an NPC so its appearance calculation can be skipped */
export function save(formID: RefID, key: JourneyKey, raceGroup: RaceGroup) {
  cache.set(formID, {
    lastSeen: Now(),
    key: key,
    raceGroup: raceGroup,
  })
}

export function get(formID: RefID) {
  return new Maybe(getCache(formID, cache)).noneToNull()
}
