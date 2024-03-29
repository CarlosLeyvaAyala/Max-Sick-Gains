import { ForceRange, forcePercent } from "DmLib/Math"
import { HumanHours } from "DmLib/Time"
import * as JDB from "JContainers/JDB"
import { LogE, LogI, LogIT, LogN, LogV, LogVT } from "../../../../debug"
import { FitJourney, TextureSignature, db } from "../../../../types/exported"
import { JDBSaveAdapter, SaverObject } from "../../../../types/saving"
import { BodyShape } from "../../../bodyslide"
import { TexturePaths, logBanner, textureIdsToPaths } from "../../../common"
import { get as getFromCache, save as saveToCache } from "../../cache/journey"
import { calculateAppearance } from "./_appearance"

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
  /** Name to identify this Journey in cache */
  get name() {
    return this._name
  }

  /** Journey data */
  protected readonly _journey: FitJourney
  /** Index of the last Journey Stage */
  protected readonly _lastStage: number

  /** Getst the current journey stage data */
  protected currentStage() {
    return this._journey.stages[this.stage]
  }

  protected capGains = ForceRange(0, 100)

  public get welcomeMsg() {
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

    LogV(`${key} Journey was created with (${journey.stages.length}) stages`)
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

    if (gains >= 100) {
      const [canProgress, doProgress, onProgress] = this.getProgressFuncs()
      return this.Change(s, gains, canProgress, doProgress, onProgress)
    } else if (gains < 0) {
      const [canRegress, doRegress, onRegress] = this.getRegressFuncs()
      return this.Change(s, gains, canRegress, doRegress, onRegress)
    }

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

  /** Gets the functions needed to make progress.
   * @returns The functions needed to make progress.
   * @remarks
   * This function was needed because object fields sometimes got lost on closures.
   */
  private getProgressFuncs(): [ChangePredicate, GainsTransform, GainsAdjust] {
    const st = this._journey.stages
    const lst = this._lastStage

    const canProgress: ChangePredicate = (x, st) => x >= 100 && st < lst
    const doProgress = (d: AdjustedData): AdjustedData => {
      // Can't go any further
      if (d.stage === lst) return { stage: lst, gains: 100 }
      // Go to next level as usual
      return { stage: d.stage + 1, gains: d.gains - 100 }
    }
    const onProgress = (d: AdjustedData, old: number): AdjustedData => {
      return {
        gains: d.gains * (st[old].minDays / st[d.stage].minDays),
        stage: d.stage,
      }
    }
    return [canProgress, doProgress, onProgress]
  }

  /** Gets the functions needed to regress.
   * @returns The functions needed to make regress.
   * @remarks
   * This function was needed because object fields sometimes got lost on closures.
   */
  private getRegressFuncs(): [ChangePredicate, GainsTransform, GainsAdjust] {
    const canRegress = (x: number, _: number) => x < 0
    const doRegress = (d: AdjustedData): AdjustedData => {
      // Can't descend any further
      if (d.stage <= 0) return { stage: 0, gains: 0 }
      // Gains will be taken care of by the adjusting function
      return { stage: d.stage - 1, gains: d.gains }
    }
    const st = this._journey.stages

    const onRegress = (d: AdjustedData, old: number): AdjustedData => {
      if (d.gains >= 0) return d
      const r = st[old].minDays / st[d.stage].minDays
      return { gains: 100 + d.gains * r, stage: d.stage }
    }
    return [canRegress, doRegress, onRegress]
  }

  protected changeStageByGains(newGains: number) {
    const a = this.adjust(newGains)
    this.gains = LogIT("Setting gains", this.capGains(a.gains))
    this.stage = LogIT("Setting stage", a.stage)
  }

  /** Initializes the Fitness Journey data the mod needs to work */
  protected initialize() {
    LogI(
      `${this._name} Fitness Journey will be initialized at stage (${this._journey.start}).`
    )
    this.gains = 0
    this.stage = this._journey.start
  }

  protected restoreVariables() {
    logBanner(`${this._name} Journey data was restored`, LogV)
    this._gains = this.restoreFloat(this.gainsKey)
    LogV(`Gains: ${this._gains}`)
    this._stage = this.restoreInt(this.stageKey)
    LogV(`Stage: ${this._stage}`)

    if (this._stage > this._lastStage) {
      this._stage = this._lastStage
      this.gains = 100
      LogE(
        `Saved Journey Stage was greater than the actual number of stages and was adjusted. Did you delete a Journey Stage in the app?`
      )
    }
  }

  /** Sets data for debugging purposes */
  public setDebug(gains: number, stage: number) {
    this.gains = gains
    this.stage = stage
    LogI(`Debug data was set to Gains: ${gains} Stage: ${stage}`)
  }

  protected capSleepingGains(hoursSlept: HumanHours) {
    return forcePercent(hoursSlept / maxSleepingHours)
  }

  public advanceStage(hoursSlept: HumanHours) {
    logBanner(`${this._name} is getting gains after sleeping`, LogI, "-")
    this.changeStageByGains(
      this.capSleepingGains(hoursSlept) * this.maxGainsPerDay() + this.gains
    )
  }

  public calculateAppearance() {
    logBanner(`Calculating ${this._name} appearance`, LogI)

    const app = calculateAppearance(
      this._journey,
      this.stage,
      this.gains,
      this.isFem(),
      this.canApplySettings()
    )

    saveToCache(this._name, app.bodyShape, app.textures)
  }

  protected isFem() {
    return this._journey.isFem
  }

  protected canApplySettings() {
    return this._journey.isFem ? db.mcm.actors.fem : db.mcm.actors.men
  }

  public getAppearanceData(
    race: string,
    texSig: TextureSignature
  ): {
    bodyShape?: BodyShape
    textures?: TexturePaths
  } {
    LogV(`Getting appearance data for ${this._name}`)

    const app = getFromCache(this._name)

    return {
      bodyShape: app?.shape,
      textures: !app
        ? undefined
        : textureIdsToPaths(
            app.textures.muscleLvl,
            app.textures.muscleType,
            app.textures.skin,
            texSig,
            race
          ),
    }
  }
}
