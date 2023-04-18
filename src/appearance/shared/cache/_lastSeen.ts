import { Now, SkyrimHours, hourSpan } from "DmLib/Time"
import { LogN } from "../../../debug"

/** Form id of the `Actor` instance; not their base ID.
 * @remarks
 * This value is valid only while playing and should not be saved in co-save,
 * since adding or moving mods around may change these RefIDs.
 */
export type RefID = number

/** Actor whose RefID may change while playing. */
export interface RecyclableActor {
  /** Last time the Actor was seen by this mod. */
  lastSeen: SkyrimHours
}

/** Max time allowed before calculating again an already seen actor. */
const timeLimit = 24

/** Gets the cached data if it exists */
export function get<V extends RecyclableActor>(
  key: RefID,
  cache: Map<RefID, V>
) {
  const d = cache.get(key)
  if (!d || hourSpan(d.lastSeen) > timeLimit) return null

  LogN("Actor was cached. Getting appearance from cache.")
  return d
}
