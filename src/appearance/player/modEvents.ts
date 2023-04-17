import { SkyrimHours } from "DmLib/Time"
import { LogIT } from "../../debug"

/** Skills belong to `skillTypes`; each one representing a broad type of skills.
 *
 * - `train` represents the relative contribution of the skill to training, and will be multiplied by the skill's own `train` contribution.
 * - `activity` is also a relative value. It represents how many days of `activity` this type of skill is worth.
 */
const skType = {
  phys: { train: 0.5, activity: 0.8 },
  mag: { train: 0.1, activity: 0.3 },
  sack: { train: 1, activity: 2 },
  sex: { train: 0.001, activity: 0.2 },
}

/** Represents a skill the player just leveled up.
 * - `skType` is the `skillTypes` each skill belongs to.
 * - `train` is the relative contribution of the skill to `training`.
 * - `activity` is the relative contribution in days of the skill to `activity`.
 */
const skills = {
  Sex: { skType: skType.sex, train: 1 },
  SackS: { skType: skType.sack, train: 0.7, activity: 0.5 },
  SackM: { skType: skType.sack, train: 1, activity: 0.75 },
  SackL: { skType: skType.sack, train: 1.5 },

  // Will likely never use these again, but still left in case of needing them
  TwoHanded: { skType: skType.phys, train: 1 },
  OneHanded: { skType: skType.phys, train: 0.7 },
  Block: { skType: skType.phys, train: 1 },
  Marksman: { skType: skType.phys, train: 0.2 },
  Archery: { skType: skType.phys, train: 0.2 },
  HeavyArmor: { skType: skType.phys, train: 1 },
  LightArmor: { skType: skType.phys, train: 0.3 },
  Sneak: { skType: skType.phys, train: 0.3 },
  Pickpocket: { skType: skType.phys, train: 0, activity: 0.1 },
  Lockpicking: { skType: skType.phys, train: 0, activity: 0.1 },
  Smithing: { skType: skType.phys, train: 0.2 },
  Alteration: { skType: skType.mag, train: 1 },
  Conjuration: { skType: skType.mag, train: 0.1 },
  Destruction: { skType: skType.mag, train: 0.7 },
  Illusion: { skType: skType.mag, train: 0.1 },
  Restoration: { skType: skType.mag, train: 1 },
}

/** Data some skill contributes to training. */
export interface TrainingData {
  activity: SkyrimHours
  training: number
}

/** Given some skill, gets what it contributes to `training` and activity.
 *
 * @param sk Skill to find.
 * @returns {@link TrainingData}
 */
export function onTraining(sk: string): TrainingData {
  sk = sk.toLowerCase()
  const s = Object.keys(skills).filter((v) => v.toLowerCase() === sk)[0]
  // @ts-ignore
  const m = skills[s]
  const A = (s1: any) => (s1.activity | 1) * s1.skType.activity
  const T = (s1: any) => s1.train * s1.skType.train
  return {
    activity: !m ? 0 : LogIT("Skill activity", A(m)),
    training: !m ? 0 : LogIT("Skill training", T(m)),
  }
}
