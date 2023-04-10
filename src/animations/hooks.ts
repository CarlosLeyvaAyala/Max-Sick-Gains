import { Animations, HookAnim } from "Animation"
import {
  Actor,
  EquippedItemType,
  Game,
  SendAnimationEventHook,
  hooks,
  writeLogs,
} from "skyrimPlatform"
import { animLog, playerId } from "../constants"
import {
  sk,
  TrainingData,
  Train,
  TrainSingleAnim,
  twoHandedTrainMult,
} from "./constants"
import { Now } from "DmLib/Time"

/** Adds an animation hook on the player. */
function Hook(animName: string, f: () => void) {
  HookAnim(animName, f, playerId, playerId)
}

function HookOneTwoHanded() {
  // Right hand
  TrainOnAttack(Animations.AttackStart, sk.Attack)
  TrainOnAttack(Animations.AttackPowerStartBackward, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartForward, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartInPlace, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartLeft, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartRight, sk.PowerAttack)

  // Left hand
  TrainOnSingle(Animations.AttackStartLeftHand, sk.Attack)
  TrainOnAttack(Animations.AttackPowerStartBackLeftHand, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartForwardLeftHand, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartInPlaceLeftHand, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartLeftLeftHand, sk.PowerAttack)
  TrainOnAttack(Animations.AttackPowerStartRightLeftHand, sk.PowerAttack)
}
function HookDualWield() {
  TrainOnSingle(Animations.AttackStartDualWield, sk.Attack)
  TrainOnSingle(Animations.AttackPowerStartDualWield, sk.PowerAttack)
}
function HookHandToHand() {
  // Left hand
  TrainOnSingle(Animations.AttackStartH2HLeft, sk.Attack)
  TrainOnSingle(Animations.AttackPowerStartForwardH2HLeftHand, sk.PowerAttack)

  // Right hand
  TrainOnSingle(Animations.AttackStartH2HRight, sk.Attack)
  TrainOnSingle(Animations.AttackPowerStartForwardH2HRightHand, sk.PowerAttack)

  // Both
  TrainOnSingle(Animations.AttackPowerStartH2HCombo, sk.PowerAttack)
}
function HookAttacks() {
  HookOneTwoHanded()
  HookDualWield()
  HookHandToHand()

  TrainOnSingle(Animations.BowAttackStart, sk.Bow)
  TrainOnSingle(Animations.CrossbowAttackStart, sk.CrossBow)
  TrainOnSingle(Animations.CrossbowDwarvenAttackStart, sk.CrossBow)
  TrainOnSingle(Animations.BashStart, sk.Bash)
}
function HookExploration() {
  TrainOnSingle(Animations.JumpDirectionalStart, sk.Jump)
  TrainOnSingle(Animations.JumpDirectionalStart, sk.Jump)

  TrainOnSpan(Animations.SwimStart, Animations.SwimStop, sk.Swim)()
  TrainOnSpan(Animations.SprintStart, Animations.SprintStop, sk.Sprint)()
  TrainOnSpan(Animations.SneakStart, Animations.SneakStop, sk.Sneak)()
}
function HookWork() {
  const exit = Animations.IdleChairExitStart

  TrainOnSpan(Animations.IdleHammerCarpenterTableEnter, exit, sk.Build)()
  TrainOnSpan(Animations.IdleSharpeningWheelStart, exit, sk.Sharpen)()
  TrainOnSpan(Animations.IdleTanningEnter, exit, sk.Build)()
  TrainOnSpan(Animations.IdleBlacksmithForgeEnter, exit, sk.Build)()
  TrainOnSpan(Animations.IdleBlackSmithingEnterStart, exit, sk.Build)()
  TrainOnSpan(
    Animations.IdleSmelterEnter,
    Animations.IdleFurnitureExitSlow,
    sk.Smelt
  )()
}

export function HookAnims() {
  HookAttacks()
  HookExploration()
  HookWork()
}
/** Changes player `training` and `activity` based on how much time has passed since two animations
 * happened.
 * @param  {Animations} start Time will start to be counted when this animation happens.
 * @param  {Animations} end Time will stop to be counted when this animation happens.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns Closure ready to be executed.
 */
function TrainOnSpan(
  start: Animations,
  end: Animations,
  skillData: TrainingData
) {
  let startTime = 0

  return () => {
    Hook(start, () => {
      startTime = Now()
    })

    Hook(end, () => {
      if (startTime > 0) {
        const dt = Now() - startTime
        Train({
          training: skillData.training * dt,
          activity: skillData.activity * dt,
        })
      }
    })
  }
}
/** Changes player `training` and `activity` when a single animation happens.
 * @param  {Animations} anim Animation that changes `training` and `activity`.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns void
 */
function TrainOnSingle(anim: Animations, skillData: TrainingData) {
  Hook(anim, () => TrainSingleAnim(skillData))
}
/** Changes player `training` and `activity` when a single animation known to belong both
 * one and two handed weapons happens.
 * @param  {Animations} anim Animation that changes `training` and `activity`.
 * @param  {TrainingData} skillData Data for the skill trained.
 * @returns void
 *
 * @remarks
 * This makes two handed weapons have more impact on training than one handed ones.
 */
function TrainOnAttack(anim: Animations, skillData: TrainingData) {
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

export function LogAnims() {
  const L = (c: SendAnimationEventHook.Context) =>
    writeLogs(animLog, `Animation name: ${c.animEventName}`)

  hooks.sendAnimationEvent.add(
    {
      enter(c) {
        L(c)
      },
      leave(c) {},
    },
    playerId,
    playerId,
    "*"
  )
}
