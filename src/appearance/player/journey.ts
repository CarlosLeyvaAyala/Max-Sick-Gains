import {
  SendGainsChange,
  SendGainsSet,
  SendTrainingSet,
} from "../../events/events_hidden"
import { Debug, storage } from "skyrimPlatform"
import { FitJourney } from "../../types/exported"
import { Journey } from "../shared/non_precalc/journey/types"
import { LogN, LogNT } from "../../debug"
import { HumanHours } from "DmLib/Time"
import { forcePercent } from "DmLib/Math"

/** Player Journey. Supports calculations and has mode data. */
export class PlayerJourney extends Journey {
  //#region training
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

  //#region lastTrained
  private readonly lastTrainedKey: string
  private _lastTrained = 0

  /** Last time the player trained. Time is in {@link Time.SkyrimHours}. */
  get lastTrained() {
    return this._lastTrained
  }
  set lastTrained(v) {
    this._lastTrained = v
    this.saveFloat(this.lastTrainedKey, this._lastTrained)
  }
  //#endregion

  constructor(key: string, journey: FitJourney) {
    super(key, journey)
    this.trainingKey = this.modKey("training")
    this.lastTrainedKey = this.modKey("lastTrained")
  }

  protected initOrGetHotReloadValues() {
    super.initOrGetHotReloadValues()

    this._training = storage[this.trainingKey] as number | 0
    this._lastTrained = storage[this.lastTrainedKey] as number | 0
  }

  /** Calculates gains when sleeping.
   *
   * @param h Hours slept.
   * @param t Training.
   * @param g Gains.
   * @returns New gains and training.
   */
  private makeGains(h: number, t: number, g: number) {
    const sleepGains = Math.min(forcePercent(h / 10), t)
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
   * @param hoursSlept How many {@link Time.HumanHours} the player slept.
   */
  public sleepEvent(hoursSlept: HumanHours) {
    LogN("--- Calculating appearance after sleeping")
    const t = LogNT("Training", this.training)
    const s = LogNT("Current player stage", this.stage)
    const g = LogNT("Gains", this.gains)

    const n = this.makeGains(hoursSlept, t, g)
    this.changeStageByGains(n.newGains)
    this.training = LogNT("Setting training", n.newTraining)

    this.sendEvents(n.gainsDelta, this.stage - s)
    // Player.Appearance.Change()
    // SendJourney()
    // sendSleep(hoursSlept)

    return n.newGains
  }

  private sendEvents(gd: number, sd: number) {
    // Widget display
    SendTrainingSet(this.training)
    SendGainsSet(LogNT("Setting gains on widget", this.gains))

    // Widget flashing
    SendGainsChange(LogNT("Gains changed by", gd))

    // Other
    const N = (m: string) => Debug.messageBox(`${m}\n\n${this.welcomeMsg()}.`)
    if (sd > 0) N("Your hard training has paid off!")
    else if (sd < 0)
      N("You lost gains, but don't fret; you can always come back.")
  }
}
