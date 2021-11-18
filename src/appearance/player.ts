import {
  ApplyBodyslide,
  ApplyMuscleDef,
  BlendMorph,
  BodyShape,
  BodyslidePreset,
  ChangeHeadSize,
  GetBodyslide,
  GetHeadSize,
  GetMuscleDefTex,
  InterpolateMusDef,
  InterpolateW,
  IsMuscleDefBanned,
  LogBs,
} from "appearance"
import {
  Combinators as C,
  DebugLib as D,
  Hotkeys,
  MapLib,
  MathLib,
  Misc as M,
  TimeLib as Time,
} from "DmLib"
import * as JDB from "JContainers/JDB"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
import {
  Actor,
  ActorBase,
  Debug,
  DxScanCode,
  Game,
  printConsole,
  storage,
  Utility,
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
import {
  LogE,
  LogI as LogIo,
  LogIT as LogITo,
  LogV as LogVo,
  LogVT as LogVTo,
} from "../debug"
import { SendGains, SendInactivity } from "../events"

const StageName = () => `Now you look ${playerStages[pStage].displayName}`

const logMsg = "Player appearance: "
const LogI = D.Log.Append(LogIo, logMsg)
const LogIT = D.Log.AppendT(LogITo, logMsg)
const LogV = D.Log.Append(LogVo, logMsg)
const LogVT = D.Log.AppendT(LogVTo, logMsg)

// Keys used for preserving variables
const modKey = (k: string) => ".maxick." + k
const gainsK = modKey("gains")
const stageK = modKey("stage")
const lastTrainK = modKey("lastTrained")
const lastUpdateK = modKey("lastUpdate")

// Variable preserving functions.
export const SaveFlt = M.JContainersToPreserving(JDB.solveFltSetter)
export const SaveInt = M.JContainersToPreserving(JDB.solveIntSetter)

/** Variables that won't be saved when in test mode. */
function TestModeBanned<T>(f: (k: string, v: T) => void) {
  return (k: string, v: T) => {
    if (!TestMode.enabled) f(k, v)
  }
}

/** Save `gains`. */
const SGains = M.PreserveVar(TestModeBanned(SaveFlt), gainsK)
/** Save `pStage`. */
const SpStage = M.PreserveVar(TestModeBanned(SaveInt), stageK)
/** Save last training. */
const SLastTrained = M.PreserveVar(TestModeBanned(SaveFlt), lastTrainK)
/** Save last update. */
const SLastUpdate = M.PreserveVar(SaveFlt, lastUpdateK)

// Script variables

/** Current player gains. */
let gains = storage[gainsK] as number | 0
/** Current Player Stage. */
let pStage = storage[stageK] as number | 0
/** Last time the player trained. Time is in {@link Time.SkyrimHours}. */
let lastTrained = storage[lastTrainK] as number | 0
/** Last time real time calculations were made. */
let lastUpdate = storage[lastUpdateK] as number | 0

const inactiveTimeLim = 48
const inactiveTimeLimSk = Time.ToSkyrimHours(inactiveTimeLim)

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
  gains = SGains(x)
}

function ModStage(delta: number) {
  SetStage(pStage + delta)
}

function SetStage(x: number) {
  pStage = SpStage(CapStage(x))
}

const CapStage = MathLib.ForceRange(0, playerStages.length - 1)

export namespace Player {
  /** Initializes player data so this mod can work. */
  export function Init() {
    LogV("Initializing")

    gains = SGains(LogVT("Gains", JDB.solveFlt(gainsK, 0)))
    pStage = SpStage(LogVT("Stage", JDB.solveInt(stageK, 0)))
    lastTrained = LogVT("Last trained", JDB.solveFlt(lastTrainK, Time.Now()))
    lastUpdate = LogVT("Last update", JDB.solveFlt(lastUpdateK, Time.Now()))

    SendAllToWidget()
  }

  /** Sends all values to widget. */
  function SendAllToWidget() {
    SendGains(gains)
    if (TestMode.enabled) {
      SendInactivity(0)
    }
  }

  /** All player appearance calculations are here. */
  export namespace Calc {
    /** Constantly updates player state. */
    export function Update() {
      const timeDelta = Time.Now() - lastUpdate
      if (timeDelta > 0)
        if (TestMode.enabled) {
          SendInactivity(0)
        } else {
          LogV("****** Update cycle ******")
          UpdateInactivity(timeDelta)
          // Calculate decay
        }

      lastUpdate = SLastUpdate(Time.Now())
      LogV(`Last update: ${lastUpdate}`)
    }

    /** Adds inactivity each update cycle.
     *
     * @param td Time delta.
     */
    function UpdateInactivity(td: number) {
      HadActivity(-td)
      const percent = (lastTrained / inactiveTimeLimSk) * 100
      SendInactivity(LogVT("Sending inactivity percent", percent))
      // _CatabolicTest(inactivityPercent)
    }

    /** Calculates new inactivity when new activity is added.
     *
     * @remarks
     * This function never allows inactivity to get out of bounds, so player can get
     * out of catabolism as soon as any kind of training is done.
     *
     * @param activity Activity value. Send negative values to simulate inactivity.
     */
    function HadActivity(activity: number) {
      const now = LogVT("Now", Time.Now())
      const Cap = (x: number) =>
        MathLib.ForceRange(now - inactiveTimeLimSk, now)(x)
      // Make sure inactivity is within acceptable values before updating
      lastTrained = SLastTrained(Cap(lastTrained) - activity)
      LogV(`Last trained: ${Time.ToHumanHours(lastTrained)}`)
    }
  }

  /** All player appearance changing stuff is here. */
  export namespace Appearance {
    const CantChangeMDef = "Can't change muscle definition."
    const MDefMcmBan = () => {
      LogI(`Muscle definition changing is banned. ${CantChangeMDef}`)
    }
    const MDefRaceBan = () => {
      LogI(`Race is banned from changing muscle defininion. ${CantChangeMDef}`)
    }
    const NoBase = () => {
      LogE("No base object for player (how is that even possible?)")
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

    /** Data needed to calculate a blended Bodyslide. */
    interface BlendData {
      /** Fitness Stage object. */
      fitStage: FitStage
      /** Player stage object */
      playerStage: PlayerStage
      /** How much this Fitness Stage contributes to blending. */
      blend: number
      /** On which `gains` this Fitness Stage appearance will be calculated. */
      gains: number
    }

    /** Data needed to calculate the final player Bodyslide. */
    interface BlendPair {
      /** Current Player Stage data. */
      blend1: BlendData
      /** Blending Player Stage data. */
      blend2: BlendData
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
      LogV(`Player Stage [${pStage}]: "${fs.iName}" [${s.fitStage}]`)

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

    /** Changes the player appearance. */
    export function Change() {
      LogV("Changing appearance.")
      const p = Game.getPlayer() as Actor
      const d = GetData(p)
      if (!d) return
      const shape = GetBodyShape(d)
      if (shape) {
        LogBs(shape.bodySlide, "Final preset", LogV)
        ApplyBodyslide(p, shape.bodySlide)
        ChangeHeadSize(p, shape.headSize)
      }
      const tex = GetMuscleDef(d)
      ApplyMuscleDef(p, d.sex, tex)
      // TODO: Change head size
    }

    function GetBodyShape(d: PlayerData): BodyShape | undefined {
      const b = GetBlends(d)
      return {
        bodySlide: GetBodySlide(d, b),
        headSize: GetHeadS(d, b),
      }
    }

    function GetHeadS(d: PlayerData, b: BlendPair) {
      const B = (bl: BlendData) => {
        if (bl.blend === 0) return 0
        const g = InterpolateW(
          bl.playerStage.bsLo,
          bl.playerStage.bsHi,
          bl.gains
        )
        const hs = GetHeadSize(bl.fitStage, d.sex, g)
        return hs * bl.blend
      }
      const s1 = LogVT("Current stage Hs", B(b.blend1))
      const s2 = LogVT("Blend stage Hs", B(b.blend2))
      return LogIT("Head size", s1 + s2)
    }

    /** Returns a fully blended Bodyslide preset. Ready to be applied on the player.
     *
     * @param d Player data.
     * @returns A fully blended {@link BodyslidePreset} or `undefined` (that last thing
     * should actually never happen).
     */
    function GetBodySlide(d: PlayerData, b: BlendPair) {
      const { blend1: b1, blend2: b2 } = b
      const L = (b: BlendData) =>
        `fitStage: ${b.fitStage.iName}, blend: ${b.blend}, gains: ${b.gains}`

      const sl1 = GetSliders(
        d,
        LogVT("Current Stage", b1, L)
      ) as BodyslidePreset
      const sl2 = b2 ? GetSliders(d, LogVT("Blend Stage", b2, L)) : undefined

      LogBs(sl1, "Current stage BS", LogV)
      LogBs(sl2, "Blend stage BS", LogV)

      return MapLib.JoinMaps(sl1, sl2, (v1, v2) => v1 + v2)
    }

    /** Returns which data will be used for blending appearance between two _Player Stages_.
     *
     * @param d Player data.
     * @returns Current and Blending stage data.
     */
    function GetBlends(d: PlayerData): BlendPair {
      const lBlendLim = d.playerStage.blend
      const uBlendLim = 100 - lBlendLim
      const currStage = d.playerStageId
      let b1 = 0
      let g2 = 0
      let blendStage = 0

      if (lBlendLim >= d.gains && currStage > 0) {
        LogV("Current stage was blended with previous")
        blendStage = currStage - 1
        g2 = 100
        b1 = MathLib.LinCurve({ x: 0, y: 0.5 }, { x: lBlendLim, y: 1 })(d.gains)
      } else if (uBlendLim <= d.gains && currStage < playerStages.length - 1) {
        LogV("Current stage was blended with next")
        blendStage = currStage + 1
        g2 = 0
        b1 = MathLib.LinCurve(
          { x: uBlendLim, y: 1 },
          { x: 100, y: 0.5 }
        )(d.gains)
      } else {
        LogV("No blending needed")
        b1 = 1
      }

      const fs1 = d.fitnessStage
      const ps1 = d.playerStage
      const ps2 = playerStages[blendStage]
      const fs2 = fitStage(ps2.fitStage)
      return {
        blend1: { fitStage: fs1, playerStage: ps1, gains: d.gains, blend: b1 },
        blend2: { fitStage: fs2, playerStage: ps2, gains: g2, blend: 1 - b1 },
      }
    }

    /** Calculates the Bodyslide associated to some blend.
     *
     * @param d Player data.
     * @param b Blending data.
     * @returns Fully formed Bodyslide preset.
     */
    function GetSliders(d: PlayerData, b: BlendData) {
      if (b.blend === 0) return undefined
      const g = InterpolateW(b.playerStage.bsLo, b.playerStage.bsHi, b.gains)
      return GetBodyslide(b.fitStage, d.sex, g, BlendMorph(b.blend), LogV)
    }

    /** Returns the muscle definition texture the player should use. */
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

      return GetMuscleDefTex(d.sex, RacialGroup.Hum, mdt, md, LogIT)
    }
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
  export const enabled = false

  /** Gains +10 hotkey listener. */
  export const Add10 = Hotkeys.ListenTo(DxScanCode.RightArrow)

  /** Gains +10 hotkey listener. */
  export const Sub10 = Hotkeys.ListenTo(DxScanCode.LeftArrow)

  /** Next Stage hotkey listener. */
  export const Next = Hotkeys.ListenTo(DxScanCode.UpArrow)

  /** Previous Stage hotkey listener. */
  export const Prev = Hotkeys.ListenTo(DxScanCode.DownArrow)

  /** Slideshow hotkey listener. */
  export const SlideShow = Hotkeys.ListenTo(DxScanCode.NumEnter)

  let slideshowRunning = false

  export function GoSlideShow() {
    if (!enabled || slideshowRunning) return
    LogI("Running Slideshow Mode")
    SetGains(0)
    SetStage(0)
    SendGains(0)
    Player.Appearance.Change()
    slideshowRunning = true

    const run = async () => {
      Debug.messageBox(
        "Slideshow mode has started. Now you can see how your character will change with training."
      )
      await Utility.wait(2)
      while (GoModGains(2)) {
        await Utility.wait(0.1)
      }
      await Utility.wait(2)
      Debug.messageBox("Slideshow has ended")
      slideshowRunning = false
    }
    run()
  }

  function LogStageChange(st: string) {
    LogI(`Going to ${st} stage (${pStage + 1}/${playerStages.length})`)
  }

  /** Go to next Fitness Stage */
  export function GoNext() {
    return GoModStage(1, "end", 100, "next", 0)
  }

  /** Go to previous Fitness Stage */
  export function GoPrev() {
    return GoModStage(-1, "start", 0, "previous", 100)
  }

  /** Changes Player Stage.
   * @returns Wether it's possible to continue going in the same direction.
   */
  function GoModStage(
    delta: number,
    cantGo: string,
    cantGoGains: number,
    chMsg: string,
    newGains: number
  ) {
    if (!enabled) return false

    const old = pStage
    ModStage(delta)
    const change = old - pStage

    let canContinue = true

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
      canContinue = false
    } else {
      LogStageChange(chMsg)
      G(newGains)
      DisplayStageName()
      canContinue = true
    }

    Player.Appearance.Change()
    return canContinue
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
    if (gains > 100) return GoNext()
    else if (gains < 0) return GoPrev()
    else Player.Appearance.Change()
    return true
  }
}
