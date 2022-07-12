import { AnimLib as A, TimeLib } from "Dmlib"
import { Actor, EquippedItemType, Game } from "skyrimPlatform"
import { Player } from "./appearance/player"
import { playerId } from "./constants"
import { mcm } from "./database"

const HadTraining = Player.Calc.Training.HadTraining
const HadActivity = Player.Calc.Activity.HadActivity
type TrainingData = Player.Calc.Training.TrainingData

/** Trains a skill as is. */
function Train(skill: TrainingData) {
  const f = mcm.training.flashOnGain
  const tm = mcm.training.trainingMult
  const am = mcm.training.activityMult
  HadTraining(skill.training * tm, f)
  HadActivity(skill.activity * am)
}

/** Trains a skill that expects activity as how many minutes it's worth. */
function TrainSingleAnim(skill: TrainingData) {
  let { training, activity } = skill
  activity = TimeLib.MinutesToSkyrimHours(activity)
  Train({ training, activity })
}

/** How much `training` is multiplied if player attacks with a two handed weapon. */
const twoHandedTrainMult = 1.7

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
const baseExploreT = exploreWorth / TimeLib.ToSkyrimHours(1)
const baseExploreA = 15
const sprintT = baseExploreT * sprintMult
const sprintA = baseExploreA * sprintMult
const sneakT = baseExploreT * sneakMult
const sneakA = baseExploreA * sneakMult

/** Skill contribution based on activity type */
const sk = {
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
}

/** Adds an animation hook on the player. */
function Hook(animName: string, f: () => void) {
  A.HookAnim(animName, f, playerId, playerId)
}

function HookOneTwoHanded() {
  // Right hand
  TrainOnAttack(A.Animations.AttackStart, sk.Attack)
  TrainOnAttack(A.Animations.AttackPowerStartBackward, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartForward, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartInPlace, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartLeft, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartRight, sk.PowerAttack)

  // Left hand
  TrainOnSingle(A.Animations.AttackStartLeftHand, sk.Attack)
  TrainOnAttack(A.Animations.AttackPowerStartBackLeftHand, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartForwardLeftHand, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartInPlaceLeftHand, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartLeftLeftHand, sk.PowerAttack)
  TrainOnAttack(A.Animations.AttackPowerStartRightLeftHand, sk.PowerAttack)
}

function HookDualWield() {
  TrainOnSingle(A.Animations.AttackStartDualWield, sk.Attack)
  TrainOnSingle(A.Animations.AttackPowerStartDualWield, sk.PowerAttack)
}

function HookHandToHand() {
  // Left hand
  TrainOnSingle(A.Animations.AttackStartH2HLeft, sk.Attack)
  TrainOnSingle(A.Animations.AttackPowerStartForwardH2HLeftHand, sk.PowerAttack)

  // Right hand
  TrainOnSingle(A.Animations.AttackStartH2HRight, sk.Attack)
  TrainOnSingle(
    A.Animations.AttackPowerStartForwardH2HRightHand,
    sk.PowerAttack
  )

  // Both
  TrainOnSingle(A.Animations.AttackPowerStartH2HCombo, sk.PowerAttack)
}

function HookAttacks() {
  HookOneTwoHanded()
  HookDualWield()
  HookHandToHand()

  TrainOnSingle(A.Animations.BowAttackStart, sk.Bow)
  TrainOnSingle(A.Animations.CrossbowAttackStart, sk.CrossBow)
  TrainOnSingle(A.Animations.CrossbowDwarvenAttackStart, sk.CrossBow)
  TrainOnSingle(A.Animations.BashStart, sk.Bash)
}

function HookExploration() {
  TrainOnSingle(A.Animations.JumpDirectionalStart, sk.Jump)
  TrainOnSingle(A.Animations.JumpDirectionalStart, sk.Jump)

  TrainOnSpan(A.Animations.SwimStart, A.Animations.SwimStop, sk.Swim)()
  TrainOnSpan(A.Animations.SprintStart, A.Animations.SprintStop, sk.Sprint)()
  TrainOnSpan(A.Animations.SneakStart, A.Animations.SneakStop, sk.Sneak)()
}

export function HookAnims() {
  HookAttacks()
  HookExploration()
}

/** Changes player `training` and `activity` based on how much time has passed since two animations
 * happened.
 * @param  {A.Animations} start Time will start to be counted when this animation happens.
 * @param  {A.Animations} end Time will stop to be counted when this animation happens.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns Closure ready to be executed.
 */
function TrainOnSpan(
  start: A.Animations,
  end: A.Animations,
  skillData: TrainingData
) {
  let startTime = 0

  return () => {
    Hook(start, () => {
      startTime = TimeLib.Now()
    })

    Hook(end, () => {
      if (startTime > 0) {
        const dt = TimeLib.Now() - startTime
        Train({
          training: skillData.training * dt,
          activity: skillData.activity * dt,
        })
      }
    })
  }
}

/** Changes player `training` and `activity` when a single animation happens.
 * @param  {A.Animations} anim Animation that changes `training` and `activity`.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns void
 */
function TrainOnSingle(anim: A.Animations, skillData: TrainingData) {
  Hook(anim, () => TrainSingleAnim(skillData))
}

/** Changes player `training` and `activity` when a single animation known to belong both
 * one and two handed weapons happens.
 * @param  {A.Animations} anim Animation that changes `training` and `activity`.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns void
 *
 * @remarks
 * This makes two handed weapons have more impact on training than one handed ones.
 */
function TrainOnAttack(anim: A.Animations, skillData: TrainingData) {
  Hook(anim, () => {
    const p = Game.getPlayer() as Actor
    const t = p.getEquippedItemType(1)
    const fixedData: TrainingData = IsTwoHanded(t)
      ? {
          training: skillData.training * twoHandedTrainMult,
          activity: skillData.activity * twoHandedTrainMult,
        }
      : skillData

    TrainSingleAnim(fixedData)
  })
}

function IsTwoHanded(t: EquippedItemType) {
  return t === EquippedItemType.Greatsword || t === EquippedItemType.Battleaxe
}
