import {
  ApplyBodyslide,
  ApplyMuscleDef,
  BlendMorph,
  BodyslidePreset,
  GetBodyslide,
  GetMuscleDefTex,
  InterpolateMusDef,
  InterpolateW,
  IsMuscleDefBanned,
  LogBs,
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
  const NoBs = () => {
    LogE(
      "No base Bodyslide preset could be calculated. This is a developer error. Please report it."
    )
  }

  /** Data needed to change the player appearance. */
  interface PlayerData {
    race: string
    sex: Sex
    gains: number
    racialGroup: RacialGroup
    /** Current player stage id. */
    playerStageId: number
    /** Current player stage object. */
    playerStage: PlayerStage
    /** Fitness Stage asociated to the current Player Stage. */
    fitnessStage: FitStage
  }

  interface BlendData {
    /** Fitness Stage object. */
    fitStage: FitStage
    /** How much this Fitness Stage contributes to blending. */
    blend: number
    /** On which `gains` this Fitness Stage appearance will be calculated. */
    gains: number
  }

  interface BlendPair {
    blend1: BlendData
    blend2?: BlendData
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
      playerStageId: pStage,
      playerStage: s,
      fitnessStage: fs,
      gains: gains,
    }
  }

  export function ChangeAppearance() {
    LogV("Changing player appearance.")
    const p = Game.getPlayer() as Actor
    const d = GetData(p)
    if (!d) return
    const bs = GetBs(d)
    if (bs) {
      LogBs(bs, "Final preset", LogV)
      ApplyBodyslide(p, bs)
    }
    const tex = GetMuscleDef(d)
    ApplyMuscleDef(p, d.sex, tex)
  }

  /** Returns a fully blended Bodyslide preset. Ready to be applied on the player.
   *
   * @param d Player data.
   * @returns A fully blended {@link BodyslidePreset} or `undefined` (that last thing
   * should actually never happen).
   */
  function GetBs(d: PlayerData): BodyslidePreset | undefined {
    const { blend1, blend2 } = GetBlends(d)
    const L = (b: BlendData) =>
      `fitStage: ${b.fitStage.iName}, blend: ${b.blend}, gains: ${b.gains}`

    const sl1 = GetSliders(d, LogVT("Current Stage", blend1, L))
    const sl2 = blend2
      ? GetSliders(d, LogVT("Blend Stage", blend2, L))
      : undefined

    if (!sl1) return D.Log.R(NoBs(), undefined)
    LogBs(sl1, "Current stage BS", LogV)
    LogBs(sl2, "Blending stage BS", LogV)
    return JoinMaps(sl1, sl2, (v1, v2) => v1 + v2)
  }

  function JoinMaps<K, V>(
    m1: Map<K, V>,
    m2: Map<K, V> | null | undefined,
    OnExistingKey: (v1: V, v2: V, k?: K) => V
  ) {
    if (!m2) return m1
    const o = new Map<K, V>(m1)
    m2.forEach((v2, k) => {
      if (o.has(k)) o.set(k, OnExistingKey(o.get(k) as V, v2, k))
      else o.set(k, v2)
    })
    return o
  }

  /** Returns which data will be used for blending appearance between two Player stages.
   *
   * @param d Player data.
   * @returns Current and Blending stage data.
   */
  function GetBlends(d: PlayerData) {
    function R(
      msg: string,
      s2?: number,
      g2?: number,
      p1?: MathLib.Point,
      p2?: MathLib.Point
    ): BlendPair {
      LogV(msg)
      // @ts-ignore
      const b1 = !s2 ? 1 : MathLib.LinCurve(p1, p2)(d.gains)
      return {
        blend1: { fitStage: d.fitnessStage, gains: d.gains, blend: b1 },
        // @ts-ignore
        blend2:
          s2 === undefined
            ? undefined
            : {
                fitStage: fitStage(playerStages[s2].fitStage),
                gains: g2,
                blend: 1 - b1,
              },
      }
    }

    const lBlendLim = d.playerStage.blend
    const uBlendLim = 100 - lBlendLim
    const currStage = d.playerStageId

    if (lBlendLim >= d.gains && currStage > 0)
      return R(
        "Current stage was blended with previous",
        currStage - 1,
        100,
        { x: 0, y: 0.5 },
        { x: lBlendLim, y: 1 }
      )
    else if (uBlendLim <= d.gains && currStage < playerStages.length - 1)
      return R(
        "Current stage was blended with next",
        currStage + 1,
        0,
        { x: uBlendLim, y: 1 },
        { x: 100, y: 0.5 }
      )
    else return R("No blending needed")
  }

  function GetSliders(d: PlayerData, b: BlendData) {
    if (b.blend === 0) return undefined
    const g = InterpolateW(d.playerStage.bsLo, d.playerStage.bsHi, b.gains)
    return GetBodyslide(b.fitStage, d.sex, g, BlendMorph(b.blend))
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

  /** Go to next Fitness Stage */
  export function GoNext() {
    GoModStage(1, "end", 100, "next", 0)
  }

  /** Go to previous Fitness Stage */
  export function GoPrev() {
    GoModStage(-1, "start", 0, "previous", 100)
  }

  function GoModStage(
    delta: number,
    cantGo: string,
    cantGoGains: number,
    chMsg: string,
    newGains: number
  ) {
    if (!enabled) return

    const old = pStage
    ModStage(delta)
    const change = old - pStage

    const G = (g: number) => {
      SetGains(g)
      LogI(`Gains were adjusted to ${g}`)
      SendGains(gains)
    }

    if (change === 0) {
      Debug.notification(
        `You reached the ${cantGo} of your journey. You can't go any further.`
      )
      G(cantGoGains)
    } else {
      LogStageChange(chMsg)
      G(newGains)
      DisplayStageName()
    }
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
    else Player.ChangeAppearance()
  }
}
