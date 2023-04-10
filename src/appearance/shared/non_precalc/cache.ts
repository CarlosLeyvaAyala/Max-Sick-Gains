import { Now, SkyrimHours, hourSpan } from "DmLib/Time"
import { LogN } from "../../../debug" // TODO: Change to proper log level
import { BodyShape } from "../../bodyslide"
import { TexturePaths } from "../../common"

/** Form id of the `Actor` instance; not their base ID. */
export type CachedFormID = number

interface CachedData {
  /** Last time the Actor was seen by this mod. */
  lastSeen: SkyrimHours
  /** Shape to apply. */
  shape: BodyShape
  /** Textures to apply. */
  textures: TexturePaths
}

type Cache = Map<CachedFormID, CachedData>
const cache: Cache = new Map()

/** Caches a generic NPC so its appearance calculation can be skipped */
export function saveToCache(
  formID: CachedFormID,
  shape: BodyShape,
  textures: TexturePaths
) {
  cache.set(formID, { lastSeen: Now(), shape: shape, textures: textures })
}

/** Gets the cached data if it exists */
export function getCached(
  formID: CachedFormID
): { shape: BodyShape; textures: TexturePaths } | null {
  const timeLimit = 24
  const d = cache.get(formID)
  if (!d) return null
  if (hourSpan(d.lastSeen) > timeLimit) return null // Actor may have already been recycled

  LogN("Actor was cached. Getting appearance from cache.")
  return { shape: d.shape, textures: d.textures }
}
