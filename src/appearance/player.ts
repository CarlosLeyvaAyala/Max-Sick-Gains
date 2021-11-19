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
import {
  SendCatabolismEnd,
  SendCatabolismStart,
  SendGains,
  SendInactivity,
  SendTrainingChange,
  SendTrainingSet,
} from "../events"

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
const trainingK = modKey("training")
const lastTrainK = modKey("lastTrained")
const lastUpdateK = modKey("lastUpdate")
const isInCatabolicK = modKey("isInCatabolic")

// Variable preserving functions.
export const SaveFlt = M.JContainersToPreserving(JDB.solveFltSetter)
export const SaveInt = M.JContainersToPreserving(JDB.solveIntSetter)
export const SaveBool = M.JContainersToPreserving(JDB.solveBoolSetter)

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
/** Save `training`. */
const STraining = M.PreserveVar(TestModeBanned(SaveFlt), trainingK)

/** Save last training. */
const SLastTrained = M.PreserveVar(TestModeBanned(SaveFlt), lastTrainK)
/** Save last update. */
const SLastUpdate = M.PreserveVar(SaveFlt, lastUpdateK)
/** Save wheter player is in catabolic state. */
const SIsInCatabolic = M.PreserveVar(TestModeBanned(SaveBool), isInCatabolicK)

// Script variables

/** Current player gains. */
let gains = storage[gainsK] as number | 0
/** Current Player Stage. */
let pStage = storage[stageK] as number | 0
/** Current training */
let training = storage[trainingK] as number | 0

/** Last time the player trained. Time is in {@link Time.SkyrimHours}. */
let lastTrained = storage[lastTrainK] as number | 0
/** Last time real time calculations were made. */
let lastUpdate = storage[lastUpdateK] as number | 0
/** Is the player in catabolic state due to inactivity? */
let isInCatabolic = storage[isInCatabolicK] as boolean | false

const inactiveTimeLim: Time.HumanHours = 48
const inactiveTimeLimSk: Time.SkyrimHours = Time.ToSkyrimHours(inactiveTimeLim)

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
const CapTraining = MathLib.ForceRange(0, 12)

export namespace Player {
  /** Initializes player data so this mod can work. */
  export function Init() {
    LogV("Initializing")

    gains = SGains(LogVT("Gains", JDB.solveFlt(gainsK, 0)))
    pStage = SpStage(LogVT("Stage", JDB.solveInt(stageK, 0)))
    training = STraining(LogVT("Traning", JDB.solveFlt(trainingK, 0)))

    lastTrained = SLastTrained(
      LogVT("Last trained init", JDB.solveFlt(lastTrainK, Time.Now()))
    )
    lastUpdate = SLastUpdate(
      LogVT("Last update init", JDB.solveFlt(lastUpdateK, Time.Now()))
    )
    isInCatabolic = SIsInCatabolic(
      LogVT("Is in catabolic state init", JDB.solveBool(isInCatabolicK))
    )

    SendAllToWidget()
  }

  /** Sends all values to widget. */
  function SendAllToWidget() {
    SendGains(gains)
    // TODO: Send training
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
          isInCatabolic = SIsInCatabolic(false)
          SendCatabolismEnd()
        } else {
          LogV("****** Update cycle ******")
          Activity.HadActivity(0) // Update inactivty and avoid values getting out of bounds
          Activity.Decay(timeDelta)
        }

      lastUpdate = SLastUpdate(Time.Now())
      LogV(`Last update: ${lastUpdate}`)
    }

    export namespace Activity {
      /** Sends events and does checks needed after inactivity change. */
      function Send() {
        LogV("--- Sending activity data")
        const hoursInactive =
          LogVT("Now", Time.Now()) - LogVT("Last trained", lastTrained)
        LogV(`Hours inactive: ${Time.ToHumanHours(hoursInactive)}`)
        const percent = (hoursInactive / inactiveTimeLimSk) * 100

        SendInactivity(LogVT("Sending inactivity percent", percent))
        CatabolicTest(percent)
      }

      /** Tests if player is in catabolic state and sends events accordingly.
       *
       * @param i Inactivity percent.
       */
      function CatabolicTest(i: number) {
        const old = isInCatabolic
        // Don't use 100 due to float and time imprecision
        isInCatabolic = LogVT("isInCatabolic", SIsInCatabolic(i >= 99.8))

        if (isInCatabolic != old) {
          LogV("There was a change in catabolic state.")
          if (isInCatabolic) {
            LogI("Entered catabolic state.")
            SendCatabolismStart()
          } else {
            LogI("Got out from catabolic state.")
            SendCatabolismEnd()
          }
        }
      }

      /** Calculates new inactivity when new activity is added.
       *
       * @remarks
       * This function never allows inactivity to get out of bounds, so player can get
       * out of catabolism as soon as any kind of training is done.
       *
       * @param activity Activity value. Send negative values to simulate inactivity.
       */
      export function HadActivity(activity: Time.SkyrimHours) {
        const now = LogVT("Now", Time.Now())
        LogV(`Last trained before: ${lastTrained}`)
        const Cap = (x: number) =>
          MathLib.ForceRange(now - inactiveTimeLimSk, now)(x)

        // Make sure inactivity is within acceptable values before updating
        const l = Cap(lastTrained)
        lastTrained = SLastTrained(Cap(l + activity))

        LogV(`Last trained after: ${lastTrained}`)
        Send()
      }

      export function Decay(td: number) {
        // ; Decay and losses calculation
        // ; int data = LuaTable("maxick.Poll", Now(), _lastPollingTime, _training, _gains, _stage, _isInCatabolic as int)
        // ; _SetGains( JMap.getFlt(data, "newGains") )
        // ; _SetTraining( JMap.getFlt(data, "newTraining") )
        // ; _SetStage( JMap.getInt(data, "newStage") )
        // ; _SendStageDelta( JMap.getInt(data, "stageDelta") )
        //   function player.Polling(now, lastPoll, training, gains, stage, inCatabolism)
        //   local PollAdjust = function (x) return (now - lastPoll) * x end
        //   local Catabolism = function (x) return l.alt2(l.SkyrimBool(inCatabolism), PollAdjust, l.K(0))(x) end
        //   local trainingDecay = PollAdjust(player.trainingDecay)
        //   -- Catabolism calculations
        //   local trainingCatabolism = Catabolism(player.trainingCatabolism)
        //   local gainsCatabolism = Catabolism(_GainsCatabolism(stage))
        //   local newStage, adjustedGains = _AdjustStage(stage, gains - gainsCatabolism)
        //   return {
        //     newGains = adjustedGains,
        //     newTraining = l.forcePositve(training - trainingCatabolism - trainingDecay),
        //     newStage = newStage,
        //     stageDelta = newStage - stage,
        //   }
        // end
      }
    }

    export namespace Training {
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
        TwoHanded: { skType: skType.phys, train: 1 },
        OneHanded: { skType: skType.phys, train: 0.7 },
        Block: { skType: skType.phys, train: 1 },
        Marksman: { skType: skType.phys, train: 0.2 },
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
        Sex: { skType: skType.sex, train: 1 },
        SackS: { skType: skType.sack, train: 0.7, activity: 0.5 },
        SackM: { skType: skType.sack, train: 1, activity: 0.75 },
        SackL: { skType: skType.sack, train: 1.5 },
      }

      export function OnTrain(sk: string) {
        LogI(`Skill level up: ${sk}`)
        const d = GetTrainingData(sk)
        HadTraining(d.training)
        Activity.HadActivity(d.activity)
      }

      export function HadTraining(delta: number) {
        const old = training
        const t = CapTraining(training + delta)
        training = LogIT("Training", STraining(t))

        SendTrainingSet(training)
        SendTrainingChange(delta)
      }

      /** Data some skill contributes to training. */
      interface TrainingData {
        activity: Time.SkyrimHours
        training: number
      }

      /** Given some skill, gets what it contributes to `training` and activity.
       *
       * @param sk Skill to find.
       * @returns {@link TrainingData}
       */
      function GetTrainingData(sk: string): TrainingData {
        const s = Object.keys(skills).filter((v) => v === sk)[0]
        // @ts-ignore
        const m = skills[s]
        const A = (s1: any) => (s1.activity | 1) * s1.skType.activity
        const T = (s1: any) => s1.train * s1.skType.train
        return {
          activity: !m ? 0 : LogIT("Skill activity", A(m)),
          training: !m ? 0 : LogIT("Skill training", T(m)),
        }
      }
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
