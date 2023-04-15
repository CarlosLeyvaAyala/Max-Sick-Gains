import { MinutesToSkyrimHours, toSkyrimHours } from "DmLib/Time"
import { Player } from "../appearance/player"
import { mcm } from "../database"
import { PlayerJourney } from "../appearance/player/journey"
import { LogN } from "../debug"

let playerJourney: PlayerJourney | null = null
const HadTraining = Player.Calc.Training.HadTraining
const HadActivity = Player.Calc.Activity.HadActivity
export type TrainingData = Player.Calc.Training.TrainingData

export const setPlayerJourney = (p: PlayerJourney) => (playerJourney = p)

/** Trains a skill as is. */
export function Train(skill: TrainingData) {
  const f = mcm.training.flashOnGain
  const tm = mcm.training.trainingMult
  const am = mcm.training.activityMult
  HadTraining(skill.training * tm, f)
  HadActivity(skill.activity * am)

  if (!playerJourney) return
  LogN("Using new animation system")
  playerJourney.hadTraining(skill.training * tm)
  playerJourney.hadActivity(skill.activity * am)
}

/** Trains a skill that expects activity as how many minutes it's worth. */
export function TrainSingleAnim(skill: TrainingData) {
  let { training, activity } = skill
  activity = MinutesToSkyrimHours(activity)
  Train({ training, activity })
}

/** How much `training` is multiplied if player attacks with a two handed weapon. */
export const twoHandedTrainMult = 1.7

const pwrMult = 2.5
const bashMult = 2
const bowMult = 1.3
const xBowMult = 0.7

/** Number of attacks needed to gain 1 training point */
const numAttacksToTrain = 80

const baseAtk = 1 / numAttacksToTrain
const pwrAtk = baseAtk * pwrMult
const bashAtk = baseAtk * bashMult
const bowAtk = baseAtk * bowMult
const xBowAtk = baseAtk * xBowMult

const baseAct = 5
const pwrAct = baseAct * pwrMult
const bashAct = baseAct * bashMult
const bowAct = baseAct * bowMult
const xBowAct = baseAct * xBowMult

const sprintMult = 1.2 // Values are high because there are usually short sprinting bursts, unlike swimming.
const sneakMult = 1.3 // Sneaking requires great physical effort

/** Training to gain for 1 hour of non stop exploring actions. */
const exploreWorth = 0.3
/** How much training is gained per hour of exploring actions. */
const baseExploreT = exploreWorth / toSkyrimHours(1)
const baseExploreA = 15
const sprintT = baseExploreT * sprintMult
const sprintA = baseExploreA * sprintMult
const sneakT = baseExploreT * sneakMult
const sneakA = baseExploreA * sneakMult

/** Skill contribution based on activity type */
export const sk = {
  // Single animation events. Activity is given in how many minutes each animation is worth.
  Attack: { training: baseAtk, activity: baseAct },
  PowerAttack: { training: pwrAtk, activity: pwrAct },
  Bash: { training: bashAtk, activity: bashAct },
  Bow: { training: bowAtk, activity: bowAct },
  CrossBow: { training: xBowAtk, activity: xBowAct },
  Jump: { training: 0.004, activity: 9 }, // Left as "magic numbers" because these work right as is. No need to base them on other numbers.

  // Animation span events. Activity and training are given as time span multipliers.
  Swim: { training: baseExploreT, activity: baseExploreA },
  Sprint: { training: sprintT, activity: sprintA },
  Sneak: { training: sneakT, activity: sneakA },
  Build: { training: baseExploreT, activity: sprintA },
  Sharpen: { training: baseExploreT * 0.5, activity: sprintA },
  Smelt: { training: sneakT, activity: sneakA },
}
