import { forcePercent } from "DmLib/Math"
import { HumanHours, Now, SkyrimHours } from "DmLib/Time"
import { Debug, printConsole } from "skyrimPlatform"
import { LogN, LogNT, LogV, LogVT } from "../../debug"
import {
  SendCatabolismEnd,
  SendGainsChange,
  SendGainsSet,
  SendInactivity,
  SendTrainingSet,
} from "../../events/events_hidden"
import { FitJourney, db } from "../../types/exported"
import { Journey } from "../shared/dynamic/journey/types"
import { catabolicCheck, hadActivity, sendActivity } from "./_activity"
import { decay, hadTraining } from "./_training"
import { sendJourney } from "./_sendJourney"

/** Player Journey. Supports calculations and has mode data. */
export class PlayerJourney extends Journey {
  //#region Property: training
  private readonly trainingKey: string
  private _training = 0

  /** Current training */
  get training() {
    return this._training
  }
  set training(v) {
    this._training = v
    this.saveFloat(this.trainingKey, this._training)
  }
  //#endregion

  //#region Property: lastTrained
  private readonly lastTrainedKey: string
  private _lastTrained = Now()

  /** Last time the player trained. Time is in {@link Time.SkyrimHours}. */
  get lastTrained() {
    return this._lastTrained
  }
  set lastTrained(v) {
    this._lastTrained = v
    this.saveFloat(this.lastTrainedKey, this._lastTrained)
  }
  //#endregion

  //#region Property: lastUpdate
  private readonly lastUpdateKey: string
  private _lastUpdate = Now()

  /** Last time real time calculations were made. */
  get lastUpdate() {
    return this._lastUpdate
  }
  set lastUpdate(v) {
    this._lastUpdate = v
    this.saveFloat(this.lastUpdateKey, this._lastUpdate)
  }
  //#endregion

  //#region Property: isInCatabolic
  private readonly isInCatabolicKey: string
  private _isInCatabolic = false

  /** Is the player in catabolic state due to inactivity? */
  get isInCatabolic() {
    return this._isInCatabolic
  }
  set isInCatabolic(v) {
    this._isInCatabolic = v
    this.saveBool(this.isInCatabolicKey, this._isInCatabolic)
  }
  //#endregion

  //#region Property: lastSlept
  private readonly lastSleptKey: string
  private _lastSlept = Now()

  /** Is the player in catabolic state due to inactivity? */
  get lastSlept() {
    return this._lastSlept
  }
  set lastSlept(v) {
    this._lastSlept = v
    this.saveFloat(this.lastSleptKey, this._lastSlept)
  }
  //#endregion

  constructor(key: string, journey: FitJourney) {
    super(key, journey)
    this.trainingKey = this.modKey("training")
    this.lastTrainedKey = this.modKey("lastTrained")
    this.isInCatabolicKey = this.modKey("isInCatabolic")
    this.lastUpdateKey = this.modKey("lastUpdate")
    this.lastSleptKey = this.modKey("lastSlept")
  }

  /** Calculates gains when sleeping.
   *
   * @param h Hours slept.
   * @param t Training.
   * @param g Gains.
   * @returns New gains and training.
   */
  private makeGains(h: number, t: number, g: number) {
    const sleepGains = Math.min(this.capSleepingGains(t), t)
    const gainsDelta = this.maxGainsPerDay() * sleepGains
    const newTraining = t - sleepGains
    return {
      gainsDelta: LogNT("Gains delta", gainsDelta),
      newTraining: LogNT("Training after gains", newTraining),
      newGains: LogNT("New raw gains", g + gainsDelta),
    }
  }

  /** Do gains calculations after sleeping.
   *
   * @param hoursSlept How many {@link HumanHours} the player slept.
   */
  public advanceStage(hoursSlept: HumanHours) {
    LogN("--- Calculating appearance after sleeping")
    const t = LogNT("Training", this.training)
    const s = LogNT("Current player stage", this.stage)
    const g = LogNT("Gains", this.gains)

    const n = this.makeGains(hoursSlept, t, g)
    this.changeStageByGains(n.newGains)
    this.training = LogNT("Setting training", n.newTraining)

    this.sendEvents(n.gainsDelta, this.stage - s)
    sendJourney(this.gains, this.stage, this._journey)
    // Player.Appearance.Change()
    // SendJourney()
    // sendSleep(hoursSlept)

    return n.newGains
  }

  private sendEvents(gd: number, sd: number) {
    // Widget display
    SendTrainingSet(this.training)
    SendGainsSet(LogVT("Setting gains on widget", this.gains))

    // Widget flashing
    SendGainsChange(LogVT("Gains changed by", gd))

    // Other
    const N = (m: string) => Debug.messageBox(`${m}\n\n${this.welcomeMsg()}.`)
    if (sd > 0) N("Your hard training has paid off!")
    else if (sd < 0)
      N("You lost gains, but don't fret; you can always come back.")
  }

  protected restoreVariables() {
    super.restoreVariables()
    this._training = this.restoreFloat(this.trainingKey)
    LogV(`Training: ${this._training}`)
    this._lastTrained = this.restoreFloat(this.lastTrainedKey)
    LogV(`Last trained: ${this._lastTrained}`)
  }

  /** Sets data for debugging purposes */
  public setDebugE(training: number, lastTrained: number) {
    this.training = training
    this.lastTrained = lastTrained
    LogV(
      `Debug data was set to Training: ${training} Last Trained: ${lastTrained}`
    )
  }

  /** Calculates new inactivity when new activity is added.
   *
   * @remarks
   * This function never allows inactivity to get out of bounds, so player can get
   * out of catabolism as soon as any kind of training is done.
   *
   * @param activity Activity value. Send negative values to simulate inactivity.
   */
  public hadActivity(activity: SkyrimHours) {
    this.lastTrained = hadActivity(activity, this.lastTrained)
    const inactivePercent = sendActivity(this.lastTrained)
    this.isInCatabolic = catabolicCheck(inactivePercent, this.isInCatabolic)
  }

  /** Decay training and/or gains.
   * @param timeDelta Time difference with last check.
   */
  private decay(timeDelta: number) {
    const d = decay(
      timeDelta,
      this.training,
      this.isInCatabolic,
      this.maxGainsPerDay()
    )

    if (d.gainsCatabolism !== 0)
      this.changeStageByGains(this.gains - d.gainsCatabolism)

    // Don't flash because decay shouldn't flash and catabolic losses are periodically flashed anyway.
    this.hadTraining(-d.trainDecay - d.trainCatabolism, false)
  }

  /** Player had training.
   * @param delta Training change.
   * @param flash Will widget flash on training change?
   */
  public hadTraining(delta: number, flash: boolean = false) {
    this.training = hadTraining(this.training, delta, flash)
  }

  public updateRT() {
    const timeDelta = Now() - this.lastUpdate
    const tm = db.mcm.testingMode.enabled

    if (timeDelta > 0)
      if (tm) {
        SendInactivity(0)
        this.isInCatabolic = false
        SendCatabolismEnd()
      } else {
        LogV("****** Update cycle ******")
        this.hadActivity(0) // Update inactivty and avoid values getting out of bounds
        this.decay(timeDelta)
      }

    this.lastUpdate = Now()
    if (timeDelta > 0 && !tm) LogV(`Last update: ${this.lastUpdate}`)
  }
}
