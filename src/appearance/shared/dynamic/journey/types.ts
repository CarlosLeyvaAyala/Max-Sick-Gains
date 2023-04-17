import { ForceRange, forcePercent } from "DmLib/Math"
import { HumanHours } from "DmLib/Time"
import * as JDB from "JContainers/JDB"
import { LogN, LogNT, LogV, LogVT } from "../../../../debug"
import { FitJourney, db } from "../../../../types/exported"
import { JDBSaveAdapter, SaverObject } from "../../../../types/saving"
import { calculateAppearance } from "./_appearance"
import { logBanner } from "../../../common"

interface AdjustedData {
  stage: number
  gains: number
}

type ChangePredicate = (gains: number, stage: number) => boolean
type GainsTransform = (d: AdjustedData) => AdjustedData
type GainsAdjust = (d: AdjustedData, oldStage: number) => AdjustedData

/** Maximum number of hours this mod will convert to training */
const maxSleepingHours = 10

/** Used to save the data of a person that has a Fitness Journey. */
export class Journey extends SaverObject {
  private readonly gainsKey: string
  private readonly stageKey: string

  /** Creates a JDB key asociated with this object. */
  protected readonly modKey: (varName: string) => string

  //#region Property: Gains
  private _gains = 0

  /** Current gains */
  get gains() {
    return this._gains
  }
  set gains(v) {
    this._gains = v
    this.saveFloat(this.gainsKey, this._gains)
  }
  //#endregion

  //#region Property: Stage
  private _stage = 0
  // TODO: Check if protect encapsulation is needed
  /** Current stage in its Journey */
  get stage() {
    return this._stage
  }
  set stage(v) {
    this._stage = v
    this.saveInt(this.stageKey, this._stage)
  }
  //#endregion

  /** Name to identify this Journey in logs */
  protected readonly _name: string
  /** Journey data */
  protected readonly _journey: FitJourney
  /** Index of the last Journey Stage */
  protected readonly _lastStage: number

  /** Getst the current journey stage data */
  protected currentStage() {
    return this._journey.stages[this.stage]
  }

  protected capGains = ForceRange(0, 100)

  protected welcomeMsg() {
    return this.currentStage().welcomeMsg
  }

  /** Gets max gains per day in the current stage as a percent */
  protected maxGainsPerDay() {
    return 100 / this.currentStage().minDays
  }

  constructor(key: string, journey: FitJourney) {
    super(
      [JDBSaveAdapter(JDB.solveStrSetter), JDB.solveStr],
      [JDBSaveAdapter(JDB.solveIntSetter), JDB.solveInt],
      [JDBSaveAdapter(JDB.solveFltSetter), JDB.solveFlt],
      [JDBSaveAdapter(JDB.solveBoolSetter), JDB.solveBool]
    )
    this._name = key
    this.modKey = (v: string) => `.maxickVars.${key}${v}`
    this.gainsKey = this.modKey("gains")
    this.stageKey = this.modKey("stage")
    this._journey = journey
    this._lastStage = journey.stages.length - 1

    LogN(`${key} Journey was created with (${journey.stages.length}) stages`)
  }

  /** Initializes variables */
  public start() {
    if (!this.keyExists(this.stageKey)) this.initialize()
    else this.restoreVariables()
  }

  /** Adjust gains and stage based on minDays.
   *
   * @param gains Current `gains` that need to be adjusted.
   */
  protected adjust(gains: number): AdjustedData {
    const s = this.stage
    LogV(`Adjusting Player Stage: s = ${s}, g = ${gains}`)
    const ProgPred: ChangePredicate = (x, st) =>
      x >= 100 && st < this._lastStage

    if (gains >= 100)
      return this.Change(s, gains, ProgPred, this.Progress, this.OnProgress)
    else if (gains < 0)
      return this.Change(
        s,
        gains,
        (x, _) => x < 0,
        this.Regress,
        this.OnRegress
      )

    return {
      stage: LogVT("Adjusted stage", s),
      gains: LogVT("Adjusted gains", gains),
    }
  }

  private Change(
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

  private Progress(d: AdjustedData): AdjustedData {
    // Can't go any further
    if (d.stage === this._lastStage)
      return { stage: this._lastStage, gains: 100 }
    // Go to next level as usual
    return { stage: d.stage + 1, gains: d.gains - 100 }
  }

  private OnProgress(d: AdjustedData, old: number): AdjustedData {
    const st = this._journey.stages
    return {
      gains: d.gains * (st[old].minDays / st[d.stage].minDays),
      stage: d.stage,
    }
  }

  private Regress(d: AdjustedData): AdjustedData {
    // Can't descend any further
    if (d.stage <= 0) return { stage: 0, gains: 0 }
    // Gains will be taken care of by the adjusting function
    return { stage: d.stage - 1, gains: d.gains }
  }

  private OnRegress(d: AdjustedData, old: number): AdjustedData {
    const st = this._journey.stages
    if (d.gains >= 0) return d
    const r = st[old].minDays / st[d.stage].minDays
    return { gains: 100 + d.gains * r, stage: d.stage }
  }

  protected changeStageByGains(newGains: number) {
    const a = this.adjust(newGains)
    this.gains = LogNT("Setting gains", this.capGains(a.gains))
    this.stage = LogNT("Setting stage", a.stage)
  }

  /** Initializes the Fitness Journey data the mod needs to work */
  protected initialize() {
    LogN(
      `${this._name} Fitness Journey will be initialized at stage (${this._journey.start}).`
    )
    this.gains = 0
    this.stage = this._journey.start
  }

  protected restoreVariables() {
    logBanner(`${this._name} Journey data was restored`, LogN)
    this._gains = this.restoreFloat(this.gainsKey)
    LogN(`Gains: ${this._gains}`)
    this._stage = this.restoreInt(this.stageKey)
    LogN(`Stage: ${this._stage}`)
  }

  /** Sets data for debugging purposes */
  public setDebug(gains: number, stage: number) {
    this.gains = gains
    this.stage = stage
    LogN(`Debug data was set to Gains: ${gains} Stage: ${stage}`)
  }

  protected capSleepingGains(hoursSlept: HumanHours) {
    return forcePercent(hoursSlept / maxSleepingHours)
  }

  public advanceStage(hoursSlept: HumanHours) {
    logBanner(`${this._name} is getting gains after sleeping`, LogN, "-")
    this.changeStageByGains(
      this.capSleepingGains(hoursSlept) * this.maxGainsPerDay() + this.gains
    )
  }

  public calculateAppearance() {
    logBanner(`Calculating ${this._name} appearance`, LogN)

    calculateAppearance(
      this._journey,
      this.stage,
      this.gains,
      this.isFem(),
      this.canApplySettings()
    )
  }

  protected isFem() {
    return this._journey.isFem
  }

  protected canApplySettings() {
    return this._journey.isFem ? db.mcm.actors.fem : db.mcm.actors.men
  }
}
