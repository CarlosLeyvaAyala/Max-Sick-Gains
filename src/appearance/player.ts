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
  Game,
  printConsole,
  storage,
  Utility,
} from "skyrimPlatform"
import {
  FitStage,
  fitStage,
  mcm,
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
  SendGainsChange,
  SendGainsSet,
  SendInactivity,
  SendJourneyAverage,
  SendJourneyByDays,
  SendJourneyByStage,
  SendTrainingChange,
  SendTrainingSet,
} from "../events/events_hidden"
import { SendSleep } from "../events/maxick_compatibility"

/** All logging funcions here log `"Player appearance: ${msg}"` because
 * this make them easier to isolate from other functionality in this mod
 * when using log viewers or searching for strings.
 */
const logMsg = "Player appearance: "
const LogI = D.Log.Append(LogIo, logMsg)
const LogIT = D.Log.AppendT(LogITo, logMsg)
const LogV = D.Log.Append(LogVo, logMsg)
const LogVT = D.Log.AppendT(LogVTo, logMsg)

// ;>========================================================
// ;>===              PRESERVING VARIABLES              ===<;
// ;>========================================================

//#region Preserving variables

// Keys used for preserving variables
const modKey = (k: string) => ".maxickVars." + k
const gainsK = modKey("gains")
const stageK = modKey("stage")
const trainingK = modKey("training")
const lastTrainK = modKey("lastTrained")
const lastUpdateK = modKey("lastUpdate")
const isInCatabolicK = modKey("isInCatabolic")
const lastSleptK = modKey("lastSlept")

// Variable preserving functions.
export const SaveFlt = M.JContainersToPreserving(JDB.solveFltSetter)
export const SaveInt = M.JContainersToPreserving(JDB.solveIntSetter)
export const SaveBool = M.JContainersToPreserving(JDB.solveBoolSetter)

/** Variables that won't be saved when in _Testing Mode_. */
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

/** Save the last time the player slept. */
const SLastSlept = M.PreserveVar(SaveFlt, lastSleptK)
//#endregion

// ;>========================================================
// ;>===                SCRIPT VARIABLES                ===<;
// ;>========================================================

//#region Script variables

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

/** What was the last time the player woke up? */
let lastSlept = storage[lastSleptK] as number | 0

const inactiveTimeLim: Time.SkyrimHours = Time.ToSkyrimHours(48)
const lastPlayerStage = playerStages.length - 1
const maxAllowedTraining = 12
//#endregion

// ;>========================================================
// ;>===                SCRIPT FUNCTIONS                ===<;
// ;>========================================================

const CurrentStage = () => playerStages[pStage]
const StageName = () => `Now you look ${CurrentStage().displayName}`
const CapStage = MathLib.ForceRange(0, lastPlayerStage)
const CapGains = MathLib.ForceRange(0, 100)
const MaxGainsPerDay = () => 100 / CurrentStage().minDays

// ;>========================================================
// ;>===               WORK IS DONE HERE                ===<;
// ;>========================================================

/** All kinds of player calculations and setting appearance. */
export namespace Player {
  /** Use these only for quick debugging. */
  export namespace QuickDebug {
    /** Puts the player in catabolic state. */
    export function EnterCatabolic() {
      pStage = SpStage(1)
      gains = SGains(0.01)
      lastTrained = SLastTrained(0)
    }

    export function DoSleep() {
      Player.Calc.SetStage(lastPlayerStage, 0)
      Player.Calc.SetGains(99.9)
      Player.Calc.SetTraining(5, 0, false)
      Sleep.SleepEvent(10)
    }
  }

  /** Initializes variables. Makes variable initialization easier to read.
   *
   * @param m Message to log when initializing.
   * @param key `string` key
   * @param defaultVal Default value to retrieve in case `key` doesn't exist.
   * @param Save Function used to save a particular value.
   * @param Get
   */
  function Ini<T>(
    m: string,
    key: string,
    defaultVal: T,
    Save: (x: T) => T,
    Get: (k: string, defaultVal: T) => T
  ) {
    return Save(LogVT(`${m} initialized to`, Get(key, defaultVal)))
  }

  /** Initializes a float variable. */
  const Flt = (m: string, k: string, d: number, S: (x: number) => number) =>
    Ini(m, k, d, S, JDB.solveFlt)
  /** Initializes an int variable. */
  const Int = (m: string, k: string, d: number, S: (x: number) => number) =>
    Ini(m, k, d, S, JDB.solveInt)
  /** Initializes a bool variable. */
  const Bool = (m: string, k: string, d: boolean, S: (x: boolean) => boolean) =>
    Ini(m, k, d, S, JDB.solveBool)

  /** Initializes player data so this mod can work. */
  export function Init() {
    LogV("Initializing")

    const now = Time.Now()

    gains = Flt("Gains", gainsK, 0, SGains)
    pStage = Int("Stage", stageK, 0, SpStage)
    training = Flt("Traning", trainingK, 0, STraining)

    lastSlept = Flt("Last slept", lastSleptK, 0, SLastSlept)

    lastTrained = Flt("Last trained", lastTrainK, now, SLastTrained)
    lastUpdate = Flt("Last update", lastUpdateK, now, SLastUpdate)
    isInCatabolic = Bool("Catabolism?", isInCatabolicK, false, SIsInCatabolic)

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
      if (timeDelta > 0 && !TestMode.enabled) LogV(`Last update: ${lastUpdate}`)
    }

    export function SetGains(g: number, delta?: number) {
      // const old = gains
      gains = SGains(g)
      // if (gains !== old)
      SendGainsSet(LogVT("Setting gains", gains))
      if (delta !== undefined) SendGainsChange(LogVT("Gains changed by", delta))
    }

    export function SetStage(st: number, delta: number) {
      pStage = SpStage(st)
      if (delta !== 0) LogV(`Setting Player Stage: ${st}`)

      const N = (m: string) => Debug.messageBox(`${m}\n\n${StageName()}.`)
      if (delta > 0) N("Your hard training has paid off!")
      else if (delta < 0)
        N("You lost gains, but don't fret; you can always come back.")
    }

    export function SetTraining(
      newTraining: number,
      delta: number,
      flash: boolean = true
    ) {
      training = LogVT("Training", STraining(newTraining))

      SendTrainingSet(training)
      if (flash) SendTrainingChange(delta)
    }

    export namespace Activity {
      /** Sends events and does checks needed after inactivity change. */
      function Send() {
        LogV("--- Sending activity data")
        const hoursInactive =
          LogVT("Now", Time.Now()) - LogVT("Last trained", lastTrained)
        LogV(`Hours inactive: ${Time.ToHumanHours(hoursInactive)}`)
        const percent = (hoursInactive / inactiveTimeLim) * 100

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
          MathLib.ForceRange(now - inactiveTimeLim, now)(x)

        // Make sure inactivity is within acceptable values before updating
        const l = Cap(lastTrained)
        lastTrained = SLastTrained(Cap(l + activity))

        LogV(`Last trained after: ${lastTrained}`)
        Send()
      }

      /** How much `training` is lost a day when in _Catabolic State_. Absolute value. */
      const trainCat = 1.8
      /** How much `gains` are lost a day when in _Catabolic State_. */
      const gainsCat = 0.8

      /** How much training is lost a day (percent).
       * @remarks
       * Training decay is dynamically calculated to allow a smoother playstyle.
       *
       * When `training >= 10`, returns `20%`. When `training == 0` returns `5%`.
       * Interpolates between those values. */
      function DynDecay() {
        const lD = mcm.training.decayMin
        const hD = mcm.training.decayMax
        const trainUpperLim = 10
        const cappedTrain = MathLib.ForceRange(0, trainUpperLim)(training)
        return MathLib.LinCurve(
          { x: 0, y: lD },
          { x: trainUpperLim, y: hD }
        )(cappedTrain)
      }

      // ; Decay and losses calculation
      export function Decay(td: number) {
        LogV("--- Decay")
        const decayRate = DynDecay()
        const PollAdjust = (x: number) => td * x * training
        const Catabolism = (x: number) => (isInCatabolic ? PollAdjust(x) : 0)

        /** Training decays all the time. No matter what. */
        const trainD = LogVT("Training decay", PollAdjust(decayRate))

        // Catabolism calculations
        const trainC = LogVT("Training catabolism", Catabolism(trainCat))
        const gainsC = Catabolism(MaxGainsPerDay() * gainsCat)
        LogV(`Gains catabolism: ${gainsC}`)
        const adjusted = Stage.Adjust(pStage, gains - gainsC)

        // Setup values

        // Don't flash because decay shouldn't flash and catabolic losses are periodically flashed anyway.
        Training.HadTraining(-trainD - trainC, false)
        SetGains(adjusted.gains)
        SetStage(adjusted.stage, adjusted.stage - pStage)
      }
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
        return {
          stage: LogVT("Adjusted stage", s),
          gains: LogVT("Adjusted gains", g),
        }
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
        if (d.stage <= 0) return { stage: 0, gains: 0 }
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

      const CapTraining = MathLib.ForceRange(0, maxAllowedTraining)

      /** Sets training according to some `delta` and sends events telling training changed.
       *
       * @param delta How much the training will change.
       * @param flash Wheter the widget will flash when calculating this.
       */
      export function HadTraining(delta: number, flash: boolean = true) {
        SetTraining(CapTraining(training + delta), delta, flash)
      }

      /** Data some skill contributes to training. */
      export interface TrainingData {
        activity: Time.SkyrimHours
        training: number
      }

      /** Given some skill, gets what it contributes to `training` and activity.
       *
       * @param sk Skill to find.
       * @returns {@link TrainingData}
       */
      function GetTrainingData(sk: string): TrainingData {
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

      const race = LogIT("Race", GetRaceEDID(p))

      const sex = b.getSex()
      LogI(`Sex: ${Sex[sex]}`)

      const racialGroup = C.O(RacialMatch, C.K(RacialGroup.Ban))(race)
      LogI(`Racial group: ${RacialGroup[racialGroup]}`)

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
      ChangeAppearance(true, true)
    }

    export function ChangeMuscleDef() {
      LogV("Changing muscle definition.")
      ChangeAppearance(false, true)
    }

    function ChangeAppearance(applyBs: boolean, applyMuscleDef: boolean) {
      const p = Game.getPlayer() as Actor
      const d = GetData(p)
      if (!d) return
      const shape = GetBodyShape(d)
      if (shape && applyBs) {
        LogBs(shape.bodySlide, "Final preset", LogV)
        ApplyBodyslide(p, shape.bodySlide)
        ChangeHeadSize(p, shape.headSize)
      }
      if (applyMuscleDef) {
        const tex = GetMuscleDef(d)
        ApplyMuscleDef(p, d.sex, tex)
      }
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
      if (!mcm.actors.player.applyMuscleDef)
        return D.Log.R(MDefMcmBan(), undefined)
      if (IsMuscleDefBanned(d.race)) return D.Log.R(MDefRaceBan(), undefined)

      const mdt = d.fitnessStage.muscleDefType
      const md = InterpolateMusDef(
        d.playerStage.muscleDefLo,
        d.playerStage.muscleDefHi,
        gains
      )
      return GetMuscleDefTex(d.sex, d.racialGroup, mdt, md, LogIT)
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
  const cfg = mcm.testingMode
  export const enabled = cfg.enabled
  if (enabled) printConsole(`+++ Max Sick Gains: TESTING MODE ENABLED`)

  const FO = (k: string) => Hotkeys.FromValue(k)
  const HK = (k: string) => Hotkeys.ListenTo(FO(k), enabled)

  /** Gains +10 hotkey listener. */
  export const Add10 = HK(cfg.hkGainsAdd10)

  /** Gains -10 hotkey listener. */
  export const Sub10 = HK(cfg.hkGainsSub10)

  /** Next Stage hotkey listener. */
  export const Next = HK(cfg.hkNext)

  /** Previous Stage hotkey listener. */
  export const Prev = HK(cfg.hkPrev)

  /** Slideshow hotkey listener. */
  export const SlideShow = HK(cfg.hkSlideshow)

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
    Sleep.SendJourney()
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

/** Sleeping calculations are done inside this file because they only concern to players. */
export namespace Sleep {
  let goneToSleepAt = 0

  /** Player went to sleep. */
  export function OnStart() {
    goneToSleepAt = LogVT("OnSleepStart", Time.Now())
  }

  /** Player woke up. */
  export function OnEnd() {
    LogI("--- Finished sleeping")
    const Ls = () => {
      lastSlept = SLastSlept(LogVT("Awaken at", Time.Now()))
    }

    if (Time.HourSpan(lastSlept) < 3) {
      LogI("You just slept. Nothing will be done.")
      Ls()
      return
    }

    const hoursSlept = LogVT("Hours slept", Time.HourSpan(goneToSleepAt))
    if (hoursSlept < 0.8) return // Do nothing. Didn't really slept.
    Ls()
    SleepEvent(hoursSlept)
  }

  /** Do gains calculations after sleeping.
   *
   * @remarks
   * This function was exported so it can be used for quick debugging.
   *
   * @param hoursSlept How many {@link Time.HumanHours} the player slept.
   */
  export function SleepEvent(hoursSlept: Time.HumanHours) {
    LogV("--- Calculating appearance after sleeping")
    const t = LogVT("Training", training)
    const s = LogVT("Current player stage", pStage)
    const g = LogVT("Gains", gains)

    const n = MakeGains(hoursSlept, t, g)
    const a = Player.Calc.Stage.Adjust(s, n.newGains)
    const newGains = CapGains(a.gains)
    const sd = a.stage - s

    Player.Calc.SetGains(newGains, a.gains)
    Player.Calc.SetStage(a.stage, sd)
    Player.Calc.SetTraining(n.newTraining, n.newTraining - t, false)

    Player.Appearance.Change()

    SendJourney()
    SendSleep(hoursSlept)
  }

  export function SendJourney() {
    const st = JourneyByStage()
    const days = JourneyByDays()
    const avg = LogIT("Journey average", (st + days) / 2)

    SendJourneyAverage(avg)
    SendJourneyByDays(days)
    SendJourneyByStage(st)
  }

  const FP = MathLib.ForcePercent

  function JourneyByStage() {
    const f = MathLib.LinCurve({ x: 0, y: 0 }, { x: playerStages.length, y: 1 })
    return LogIT("Journey by stage", FP(f(pStage + gains / 100)))
  }

  function JourneyByDays() {
    LogV("Calculating journey by days")

    const SumDays = (a: number, c: PlayerStage) => a + c.minDays
    const totalDays = playerStages.reduce(SumDays, 0)
    const c = CurrentStage().minDays * (gains / 100)
    const pastDays =
      (pStage === 0 ? 0 : playerStages.slice(0, pStage).reduce(SumDays, 0)) +
      LogVT("Current stage days passed", c)

    const r = LogVT("Past days", pastDays) / LogVT("Total days", totalDays)

    return LogIT("Journey by days", FP(r))
  }

  /** Calculates gains when sleeping.
   *
   * @param h Hours slept.
   * @param t Training.
   * @param g Gains.
   * @returns New gains and training.
   */
  function MakeGains(h: number, t: number, g: number) {
    const sleepGains = Math.min(MathLib.ForcePercent(h / 10), t)
    const gainsDelta = MaxGainsPerDay() * sleepGains
    const newTraining = t - sleepGains
    return {
      gainsDelta: LogVT("Gains delta", gainsDelta),
      newTraining: LogVT("Training after gains", newTraining),
      newGains: LogVT("New raw gains", g + gainsDelta),
    }
  }
}
