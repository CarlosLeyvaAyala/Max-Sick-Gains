import { Actor, ActorBase } from "skyrimPlatform"
import { Sex } from "../../database"
import { RaceEDID } from "../common"
import { LogE } from "../../debug"
import { getEspAndId } from "DmLib/Form"
import { GetActorRaceEditorID } from "PapyrusUtil/MiscUtil"
import { tryE } from "DmLib/Misc"
import { getErrorMsg } from "DmLib/Error"

/** Data needed to solve an `Actor` appearance. */

export interface ActorData {
  /** The `Actor` per se */
  actor: Actor
  /** The leveled `ActorBase` the `Actor` belongs to */
  base: ActorBase
  /** Male or female? */
  sex: Sex
  /** TES class. */
  class: string
  /** Esp file where the actor was defined */
  esp: string
  /** FormId of `base` inside its esp file */
  fixedFormId: number
  /** Full name of the `Actor` */
  name: string
  /** Race EDID for the `Actor` */
  race: RaceEDID
  /** `Actor` weight. [0..100] */
  weight: number
  /** Current in game formID. Used for caching. */
  formID: number
}

/** Gets all `Actor` needed data to process them.
 *
 * @param a `Actor` to get data from.
 * @returns All needed data.
 */
export function getActorData(a: Actor | null): ActorData | null {
  if (!a) return null

  try {
    const l = a.getLeveledActorBase()
    const b = a.getBaseObject()
    if (!l || !b) {
      LogE("GetActorData: Couldn't find an ActorBase. Is that even possible?")
      return null
    }

    // Using base because getEsp fails for leveled actors
    const { modName, fixedFormId } = getEspAndId(b)

    return {
      actor: a,
      base: l,
      sex: l.getSex(),
      class: l.getClass()?.getName() || "",
      name: l.getName() || "",
      race: GetActorRaceEditorID(a),
      esp: modName,
      fixedFormId: fixedFormId,
      weight: l.getWeight(),
      formID: a.getFormID(),
    }
  } catch (error) {
    LogE(
      getErrorMsg(
        `There was an error trying to get the NPC data. This rarely happens and cause is unknown.:\n${error}`
      )
    )
    return null
  }
}
