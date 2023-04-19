import { Maybe } from "Maybe"
import { BodyShape } from "../../bodyslide"

export type JourneyKey = string

/** Texture IDs of the actor.
 * @remarks
 * These are not precalculated because the racial signature is known until the very end.
 */
export interface TextureIDs {
  muscle?: number
  skin?: number
}

interface CachedAppearance {
  /** Shape to apply. */
  shape: BodyShape
  /** Textures to apply. */
  textures: TextureIDs
}

type AppearanceCache = Map<JourneyKey, CachedAppearance>
const cache: AppearanceCache = new Map()

/** Caches a precalculated Journey appearance */
export function save(key: JourneyKey, shape: BodyShape, textures: TextureIDs) {
  cache.set(key, { shape: shape, textures: textures })
}

/** Gets the cached data if it exists */
export function get(
  key: JourneyKey
): { shape: BodyShape; textures: TextureIDs } | null {
  return new Maybe(cache.get(key)).map((d) => ({
    shape: d.shape,
    textures: d.textures,
  })).noneAsNull
}
