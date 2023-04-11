import { ForceRange } from "DmLib/Math"
import { storage } from "skyrimPlatform"
import { LogN, LogNT, LogV, LogVT } from "../../../../debug"
import { FitJourney } from "../../../../types/exported"
import { SaverObject } from "../../../../types/saving"

interface AdjustedData {
  stage: number
  gains: number
}

type ChangePredicate = (gains: number, stage: number) => boolean
type GainsTransform = (d: AdjustedData) => AdjustedData
type GainsAdjust = (d: AdjustedData, oldStage: number) => AdjustedData

/** Used to save the data of a person that has a Fitness Journey. */
export class Journey extends SaverObject {
  private readonly gainsKey: string
  private readonly stageKey: string

  /** Creates a JDB key asociated with this object. */
  protected readonly modKey: (varName: string) => string

  /** Initializes values or gets them from the storage map when hot reloading. */
  protected initOrGetHotReloadValues() {
    this._gains = storage[this.gainsKey] as number | 0
    this._stage = storage[this.stageKey] as number | 0
  }

  //#region Gains
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

  //#region Stage
  private _stage = 0
  /** Current stage in its Journey */
  get stage() {
    return this._stage
  }
  set stage(v) {
    this._stage = v
    this.saveInt(this.stageKey, this._stage)
  }
  //#endregion

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
    super()
    this.modKey = (v: string) => `.maxickVars.${key}${v}`
    this.gainsKey = this.modKey("gains")
    this.stageKey = this.modKey("stage")
    this.initOrGetHotReloadValues()
    this._journey = journey
    this._lastStage = journey.stages.length - 1

    LogN(
      `${key} Journey was initialized with (${journey.stages.length}) stages`
    )
  }

  /** Adjust gains and stage based on minDays.
   *
   * @param g Current `gains` that need to be adjusted.
   */
  protected adjust(g: number): AdjustedData {
    const s = this.stage
    LogV(`Adjusting Player Stage: s = ${s}, g = ${g}`)
    const ProgPred: ChangePredicate = (x, st) =>
      x >= 100 && st < this._lastStage

    if (g >= 100)
      return this.Change(s, g, ProgPred, this.Progress, this.OnProgress)
    else if (g < 0)
      return this.Change(s, g, (x, _) => x < 0, this.Regress, this.OnRegress)

    return {
      stage: LogVT("Adjusted stage", s),
      gains: LogVT("Adjusted gains", g),
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

  public changeStageByGains(newGains: number) {
    const a = this.adjust(newGains)
    this.gains = LogNT("Setting gains", this.capGains(a.gains))
    this.stage = LogNT("Setting stage", a.stage)
  }
}
