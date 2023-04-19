import { Now } from "DmLib/Time"
import { BodyShape } from "../../bodyslide"
import { TexturePaths } from "../../common"
import { RecyclableActor, RefID, get } from "./_lastSeen"
import { Maybe } from "Maybe"

interface CachedData extends RecyclableActor {
  /** Shape to apply. */
  shape: BodyShape
  /** Textures to apply. */
  textures: TexturePaths
}

type Cache = Map<RefID, CachedData>
const cache: Cache = new Map()

/** Caches an NPC so its appearance calculation can be skipped */
export function saveToCache(
  formID: RefID,
  shape: BodyShape,
  textures: TexturePaths
) {
  cache.set(formID, { lastSeen: Now(), shape: shape, textures: textures })
}

/** Gets the cached data if it exists */
export function getCached(formID: RefID) {
  return new Maybe(get(formID, cache))
    .map((d) => ({
      shape: d.shape,
      textures: d.textures,
    }))
    .noneToNull()
}
