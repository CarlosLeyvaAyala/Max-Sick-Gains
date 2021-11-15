import { Hotkeys, MathLib } from "DmLib"
import * as JDB from "JContainers/JDB"
import { Debug, DxScanCode, Game, storage } from "skyrimPlatform"
import { playerStages } from "../database"
import { LogI, LogV, LogVT } from "../debug"
import { SendGains } from "../events"

/** _Testing Mode_ operations.
 *
 * @remarks
 * Testing mode is used for testing the player's appearance before settling with the
 * final Player Stages configuration.
 *
 * It offers access to hotkeys to cycle through Player Stages. All gains, losses and
 * inactivity calculations are stopped while in this mode.
 */
export namespace TestMode {
  // TODO: Read from settings
  export const enabled = true

  /** Gains +10 hotkey listener. */
  export const Add10 = Hotkeys.ListenTo(DxScanCode.RightArrow)

  /** Gains +10 hotkey listener. */
  export const Sub10 = Hotkeys.ListenTo(DxScanCode.LeftArrow)

  /** Next Stage hotkey listener. */
  export const Next = Hotkeys.ListenTo(DxScanCode.UpArrow)

  /** Previous Stage hotkey listener. */
  export const Prev = Hotkeys.ListenTo(DxScanCode.DownArrow)

  function LogStageChange(st: string) {
    LogI(`Going to ${st} stage (${pStage + 1}/${playerStages.length})`)
  }

  const IsFirstStage = () => pStage <= 0
  const IsLastStage = () => pStage >= playerStages.length - 1

  function GainsByStageChange(capReached: boolean, cap: number, goto: number) {
    if (capReached) SetGains(cap)
    else SetGains(goto)
    SendGains(gains)
    LogI(`Gains were adjusted to: ${gains}`)
  }

  /** Go to next Fitness Stage */
  export function GoNext() {
    if (!enabled) return
    ModStage(1)
    LogStageChange("next")
    GainsByStageChange(IsLastStage(), 100, 0)
    DisplayStageName()
  }

  /** Go to previous Fitness Stage */
  export function GoPrev() {
    if (!enabled) return
    const old = pStage
    ModStage(-1)
    LogStageChange("previous")
    GainsByStageChange(IsFirstStage() && pStage == old, 0, 100)
    DisplayStageName()
  }

  /** Gains +10 */
  export function GoAdd10() {
    GoModGains(10)
  }

  /** Gains -10 */
  export function GoSub10() {
    GoModGains(-10)
  }

  function GoModGains(delta: number) {
    if (!enabled) return
    ModGains(delta)
    LogGainsDelta(delta)()
    SendGains(gains)
    if (gains >= 100) GoNext()
    else if (gains < 0) GoPrev()
    // Mod(
    //   () => {
    //     ModGains(delta)
    //   },
    //   LogGainsDelta(delta),
    //   () => {
    //     SendGains(gains)
    //   },
    //   () => {
    //     if (gains >= 100) GoNext()
    //     else if (gains < 0) GoPrev()
    //   }
    // )
  }

  /** Modifies a variable if testing mode is enabled. */
  // function Mod(Change: void, Log: void, SendEvent: void) {
  function Mod(
    Change: VoidFunc,
    Log: VoidFunc,
    SendEvent: VoidFunc,
    Navigate: VoidFunc
  ) {
    if (!enabled) return
    ModVariable(Change, Log, SendEvent)
    Navigate()
    // TODO: Change player appearance
  }
}

type VoidFunc = () => void
// function ModVariable(Change: void, Log: void, SendEvent: void) {
function ModVariable(Change: VoidFunc, Log: VoidFunc, SendEvent: VoidFunc) {
  Change()
  Log()
  SendEvent()
}

const StageName = () => `Now you look ${playerStages[pStage].displayName}`

function DisplayStageName() {
  Debug.notification(StageName())
}

function LogGainsDelta(delta: number) {
  return () => {
    LogI(`Gains ${delta < 0 ? "" : "+"}${delta}: ${gains}`)
  }
}

function ModGains(delta: number) {
  SetGains(gains + delta)
}

function SetGains(x: number) {
  gains = x
  storage["gains"] = gains
  if (!TestMode.enabled) JDB.solveFltSetter(gainsK, gains, true)
}

function ModStage(delta: number) {
  SetStage(pStage + delta)
}

function SetStage(x: number) {
  pStage = CapStage(x)
  storage["stage"] = pStage
  if (!TestMode.enabled) JDB.solveIntSetter(stageK, pStage, true)
}

let gains = storage["gains"] as number | 0
let pStage = storage["stage"] as number | 0
const gainsK = ".maxick.gains"
const stageK = ".maxick.stage"
const CapStage = MathLib.ForceRange(0, playerStages.length - 1)

export namespace Player {
  export function Init() {
    LogV("Initializing player")

    SetGains(LogVT("Gains", JDB.solveInt(gainsK, 0)))
    SetStage(LogVT("Stage", JDB.solveInt(stageK, 0)))
  }
}
