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
  SendGainsSet,
  SendInactivity,
  SendTrainingChange,
  SendTrainingSet,
} from "../events"

const logMsg = "Player appearance: "
const LogI = D.Log.Append(LogIo, logMsg)
const LogIT = D.Log.AppendT(LogITo, logMsg)
const LogV = D.Log.Append(LogVo, logMsg)
const LogVT = D.Log.AppendT(LogVTo, logMsg)

// Keys used for preserving variables
const modKey = (k: string) => ".maxickVars." + k
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

// Script functions

const CurrentStage = () => playerStages[pStage]
const StageName = () => `Now you look ${CurrentStage().displayName}`

const lastPlayerStage = playerStages.length - 1

const CapStage = MathLib.ForceRange(0, lastPlayerStage)

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
    SendGainsSet(gains)
    SendTrainingSet(training)
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
      if (timeDelta > 0) LogV(`Last update: ${lastUpdate}`)
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

      /** How much `training` is lost a day when in _Catabolic State_. Absolute value. */
      const trainCat = 0.5
      /** How much `training` is lost a day due to decay. Absolute value. */
      const trainDecay = 0.2
      /** How much `gains` are lost a day when in _Catabolic State_. */
      const gainsCat = 0.5

      // ; Decay and losses calculation
      // ; _SetGains( JMap.getFlt(data, "newGains") )
      // ; _SetStage( JMap.getInt(data, "newStage") )
      // ; _SendStageDelta( JMap.getInt(data, "stageDelta") )
      export function Decay(td: number) {
        LogI("--- Decay")
        const PollAdjust = (x: number) => td * x
        const Catabolism = (x: number) => (isInCatabolic ? PollAdjust(x) : 0)

        /** Training decays all the time. No matter what. */
        const trainD = LogVT("Training decay", PollAdjust(trainDecay))

        // Catabolism calculations
        const trainC = LogVT("Training catabolism", Catabolism(trainCat))
        const gainsC = Catabolism((1 / CurrentStage().minDays) * gainsCat)
        LogV(`Gains catabolism: ${gainsC}`)
        const adjusted = Stage.Adjust(pStage, gains - gainsC + 10)

        // Setup values

        // Don't flash because decay shouldn't flash and catabolic flashes are periodically flashed anyway.
        Training.HadTraining(-trainD - trainC, false)
        SetGains(adjusted.gains)
        SetStage(adjusted.stage, adjusted.stage - pStage)
      }

      function SetGains(g: number) {
        gains = LogIT("Setting gains", SGains(g))
        SendGainsSet(gains)
      }

      function SetStage(st: number, delta: number) {}
    }

    export namespace Stage {
      export interface AdjustedData {
        stage: number
        gains: number
      }

      type ChangePredicate = (gains: number, stage: number) => boolean
      type GainsTransform = (d: AdjustedData) => AdjustedData
      type GainsAdjust = (d: AdjustedData, oldStage: number) => AdjustedData

      /**
       *
       * @param s Current _Player Stage_ id.
       * @param g Current `gains` that need to be adjusted.
       */
      export function Adjust(s: number, g: number): AdjustedData {
        LogV(`Adjusting Player Stage: s = ${s}, g = ${g}`)
        const ProgPred: ChangePredicate = (x, st) =>
          x >= 100 && st < lastPlayerStage

        if (g >= 100) return Change(s, g, ProgPred, Progress, OnProgress)
        else if (g < 0) return Change(s, g, (x) => x < 0, Regress, OnRegress)
        return { stage: s, gains: g }
      }

      function Change(
        stage: number,
        gains: number,
        Predicate: ChangePredicate,
        f: GainsTransform,
        AdjustGains: GainsAdjust
      ): AdjustedData {
        let r: AdjustedData = { stage: stage, gains: gains }
        while (Predicate(r.gains, r.stage)) {
          const old = r.stage
          r = f(r)
          r = AdjustGains(r, old)
        }
        return r
      }

      function Progress(d: AdjustedData): AdjustedData {
        // Can't go any further
        if (d.stage === lastPlayerStage)
          return { stage: lastPlayerStage, gains: 100 }
        // Go to next level as usual
        return { stage: d.stage + 1, gains: d.gains - 100 }
      }

      function OnProgress(d: AdjustedData, old: number): AdjustedData {
        const st = playerStages
        return {
          gains: d.gains * (st[old].minDays / st[d.stage].minDays),
          stage: d.stage,
        }
      }

      function Regress(d: AdjustedData): AdjustedData {
        // Can't descend any further
        if (d.stage <= 1) return { stage: 1, gains: 0 }
        // Gains will be taken care of by the adjusting function
        return { stage: d.stage - 1, gains: d.gains }
      }

      function OnRegress(d: AdjustedData, old: number): AdjustedData {
        if (d.gains >= 0) return d
        const r = playerStages[old].minDays / playerStages[d.stage].minDays
        return { gains: 100 + d.gains * r, stage: d.stage }
      }
    }

    /** Training related operations and data. */
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

      const CapTraining = MathLib.ForceRange(0, 12)

      /** Sets training according to some `delta` and sends events telling training changed.
       *
       * @param delta How much the training will change.
       * @param flash Wheter the widget will flash when calculating this.
       */
      export function HadTraining(delta: number, flash: boolean = true) {
        const old = training
        const t = CapTraining(training + delta)
        training = LogIT("Training", STraining(t))

        SendTrainingSet(training)
        if (flash) SendTrainingChange(delta)
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

      const s = CurrentStage()
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
      } else if (uBlendLim <= d.gains && currStage < lastPlayerStage) {
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

  export function GoSlideShow() {
    if (!enabled || slideshowRunning) return
    LogI("Running Slideshow Mode")
    SetGains(0)
    SetStage(0)
    SendGainsSet(0)
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
      SendGainsSet(gains)
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
    SendGainsSet(gains)
    if (gains > 100) return GoNext()
    else if (gains < 0) return GoPrev()
    else Player.Appearance.Change()
    return true
  }
}

export namespace Sleep {
  let lastSlept = 0
  let goneToSleepAt = 0

  /** Player went to sleep. */
  export function OnStart() {
    goneToSleepAt = LogVT("OnSleepStart", Time.Now())
  }

  /** Player woke up. */
  export function OnEnd() {
    const Ls = () => {
      lastSlept = LogVT("Awaken at", Time.Now())
    }

    if (Time.HourSpan(lastSlept) < 0.2) {
      LogE("You just slept. Nothing will be done.")
      Ls()
      return
    }

    const hoursSlept = LogVT("Time slept", Time.HourSpan(goneToSleepAt))
    if (hoursSlept < 1) return // Do nothing. Didn't really slept.
    Ls()
    SleepEvent(hoursSlept)
  }

  function SleepEvent(hoursSlept: Time.HumanHours) {
    Game.getPlayer()?.sendModEvent("Sleep", "", hoursSlept)
    LogV("Calculating player appearance")
  }
}
