import {
  ApplyMuscleDef,
  GetMuscleDefTex,
  InterpolateMusDef,
  IsMuscleDefBanned,
} from "appearance"
import { Combinators as C, DebugLib as D, Hotkeys, MathLib } from "DmLib"
import * as JDB from "JContainers/JDB"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
import {
  Actor,
  ActorBase,
  Debug,
  DxScanCode,
  Game,
  storage,
} from "skyrimPlatform"
import {
  FitStage,
  fitStage,
  PlayerStage,
  playerStages,
  RacialGroup,
  RacialMatch,
  Sex,
} from "../database"
import { LogE, LogI, LogV, LogVT } from "../debug"
import { SendGains } from "../events"

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
  /** Initializes player data so this mod can work. */
  export function Init() {
    LogV("Initializing player")

    SetGains(LogVT("Gains", JDB.solveInt(gainsK, 0)))
    SetStage(LogVT("Stage", JDB.solveInt(stageK, 0)))
  }

  const CantChangeMDef = "Can't change muscle definition."
  const MDefMcmBan = () => {
    LogI(`Muscle definition changing is banned for player. ${CantChangeMDef}`)
  }
  const MDefRaceBan = () => {
    LogI(
      `Player race is banned from changing muscle defininion. ${CantChangeMDef}`
    )
  }
  const NoBase = () => {
    LogE("No base object for player (how is that even possible?)")
  }

  /** Data needed to change the player appearance. */
  interface PlayerData {
    race: string
    sex: Sex
    racialGroup: RacialGroup
    /** Current player stage object. */
    playerStage: PlayerStage
    /** Fitness Stage asociated to the current Player Stage. */
    fitnessStage: FitStage
  }

  /** Gets the data needed to change the player appearance. */
  function GetData(p: Actor): PlayerData | undefined {
    const b = ActorBase.from(p.getBaseObject())
    if (!b) return D.Log.R(NoBase(), undefined)

    const race = LogVT("Race", GetRaceEDID(p))

    const sex = b.getSex()
    LogV(`Sex: ${Sex[sex]}`)

    const racialGroup = C.O(RacialMatch, C.K(RacialGroup.Ban))(race)
    LogV(`Racial group: ${RacialGroup[racialGroup]}`)

    const s = playerStages[pStage]
    const fs = fitStage(s.fitStage)
    LogV(`Player stage [${pStage}]: "${fs.iName}" [${s.fitStage}]`)

    return {
      race: race,
      sex: sex,
      racialGroup: racialGroup,
      playerStage: s,
      fitnessStage: fs,
    }
  }

  export function ChangeAppearance() {
    LogV("Changing player appearance.")
    const p = Game.getPlayer() as Actor
    const d = GetData(p)
    if (!d) return
    const tex = GetMuscleDef(d)
    ApplyMuscleDef(p, d.sex, tex)
  }

  function GetMuscleDef(d: PlayerData) {
    // TODO: read from settings
    const canChange = true
    if (!canChange) return D.Log.R(MDefMcmBan(), undefined)
    if (IsMuscleDefBanned(d.race)) return D.Log.R(MDefRaceBan(), undefined)

    const mdt = d.fitnessStage.muscleDefType
    const md = InterpolateMusDef(
      d.playerStage.muscleDefLo,
      d.playerStage.muscleDefHi,
      gains
    )

    return GetMuscleDefTex(d.sex, RacialGroup.Hum, mdt, md)
  }
}

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
    Player.ChangeAppearance()
  }

  /** Go to previous Fitness Stage */
  export function GoPrev() {
    if (!enabled) return
    const old = pStage
    ModStage(-1)
    LogStageChange("previous")
    GainsByStageChange(IsFirstStage() && pStage == old, 0, 100)
    DisplayStageName()
    Player.ChangeAppearance()
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
    if (gains > 100) GoNext()
    else if (gains < 0) GoPrev()
    Player.ChangeAppearance()
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
