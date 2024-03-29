import { Player } from "DmLib/Actor"
import { R as LogR } from "DmLib/Log"
import { HumanHours, Now, SkyrimHours } from "DmLib/Time"
import { Maybe } from "Maybe"
import { ActorBase, Debug, printConsole } from "skyrimPlatform"
import { Sex } from "../../database"
import { LogE, LogI, LogIT, LogN, LogV, LogVT } from "../../debug"
import {
  SendCatabolismEnd,
  SendGainsChange,
  SendGainsSet,
  SendInactivity,
  SendTrainingSet,
} from "../../events/events_hidden"
import { FitJourney, RaceGroup, db } from "../../types/exported"

import { getRaceSignature, logBanner, raceSexToTexSignature } from "../common"
import {
  ShapeSetter,
  applyBodyShape,
  dontApplyBodyShape,
} from "../nioverride/morphs"
import { TextureSetter, applyTextures } from "../nioverride/textures"
import { getActorData } from "../shared/ActorData"
import { Journey } from "../shared/dynamic/journey/types"
import { catabolicCheck, hadActivity, sendActivity } from "./_activity"
import { sendJourney } from "./_sendJourney"
import { decay, hadTraining } from "./_training"

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
    const sleepGains = Math.min(this.capSleepingGains(h), t)
    const gainsDelta = this.maxGainsPerDay() * sleepGains
    const newTraining = t - sleepGains
    return {
      gainsDelta: LogVT("Gains delta", gainsDelta),
      newTraining: LogVT("Training after gains", newTraining),
      newGains: LogVT("New raw gains", g + gainsDelta),
    }
  }

  /** Do gains calculations after sleeping.
   *
   * @param hoursSlept How many {@link HumanHours} the player slept.
   */
  public advanceStage(hoursSlept: HumanHours) {
    logBanner("Calculating player gains after sleeping", LogI, "-")
    const t = LogIT("Training", this.training)
    const s = LogIT("Current player stage", this.stage)
    const g = LogIT("Gains", this.gains)

    const n = this.makeGains(hoursSlept, t, g)
    this.changeStageByGains(n.newGains)
    this.training = LogIT("Setting training", n.newTraining)

    this.sendEvents(n.gainsDelta, this.stage - s)
    sendJourney(this.gains, this.stage, this._journey)

    return n.newGains
  }

  private sendEvents(gd: number, sd: number) {
    // Widget display
    SendTrainingSet(this.training)
    SendGainsSet(LogVT("Setting gains on widget", this.gains))
    this.sendStageName()

    // Widget flashing
    SendGainsChange(LogVT("Gains changed by", gd))

    // Other
    const N = (m: string) => Debug.messageBox(`${m}\n\n${this.welcomeMsg}.`)
    if (sd > 0) N("Your hard training has paid off!")
    else if (sd < 0)
      N("You lost gains, but don't fret; you can always come back.")
  }

  /** Directly sets the player gains while in Testing Mode.
   * @remarks
   * ***WARNING***: never call this from any other places than the
   * Testing Mode functions.
   * Since these methods are designed to work only from them.
   */
  public testModeSetGains(x: number) {
    this.gains = x
    SendGainsSet(this.gains)
    sendJourney(this.gains, this.stage, this._journey)
    this.sendStageName()
  }

  /** Sends the widget data from the configuration app to Papyrus. */
  public sendWidgetData() {
    this.sendStageName()
    this.sendWidgetPosition()
  }

  /** Sends widget meters positions to Papyrus.
   * @remarks
   * See `OnMaxickSetMeters` to get the structure of the data to be sent. */
  public sendWidgetPosition() {
    const m = db.mcm.widget.meters
    const m1 = `${m["1"].x}|${m["1"].y}|${m["1"].w}|${m["1"].h}`
    const m2 = `${m["2"].x}|${m["2"].y}|${m["2"].w}|${m["2"].h}`
    const m3 = `${m["3"].x}|${m["3"].y}|${m["3"].w}|${m["3"].h}`
    const data = `${m1}|${m2}|${m3}`
    Player().sendModEvent("MaxickWidgetSetMeters", data, 0.0)
  }

  /** Sends the current Fitness Stage name to the widget so it can
   * display it.
   */
  public sendStageName() {
    const name = this.currentStage().displayName
    Player().sendModEvent("MaxickWidgetSetStageName", name, 0.0)
  }

  protected restoreVariables() {
    super.restoreVariables()
    const LL = LogVT
    const RF = (msg: string, k: string) => LL(msg, this.restoreFloat(k))
    const RB = (msg: string, k: string) => LL(msg, this.restoreBool(k))

    this._training = RF("Training", this.trainingKey)
    this._lastTrained = RF("Last trained", this.lastTrainedKey)
    this._lastUpdate = RF("Last update", this.lastUpdateKey)
    this._lastSlept = RF("Last slept", this.lastSleptKey)
    this._isInCatabolic = RB("Is in catabolic state?", this.isInCatabolicKey)
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

  protected isFem() {
    const NoBase = () => {
      LogE(
        "No base object for player (how is that even possible?). Let's assume it's a woman."
      )
    }
    const b = ActorBase.from(Player().getBaseObject())
    if (!b) return LogR(NoBase(), true)
    return Sex.female === b.getSex()
  }

  protected canApplySettings() {
    return db.mcm.actors.player
  }

  private _applyAppearance(setShape: ShapeSetter, setTextures: TextureSetter) {
    logBanner("Setting player appearance", LogI)
    const a = Player()

    const app = new Maybe(getActorData(a))
      .map((d) => {
        const rg = getRaceSignature(d.race) as RaceGroup
        if (!rg) {
          LogE(
            "Can not change the appearance of an unknown race. Setup your player race at Max Sick Gains App > MCM > Races"
          )
          return null
        }
        return {
          data: d,
          sig: raceSexToTexSignature(rg, d.sex),
        }
      })
      .map(({ data: d, sig: texSig }) => ({
        appearance: this.getAppearanceData(d.race, texSig),
        sex: d.sex,
      })).noneAsUndefined

    if (!app) return

    setShape(a, app.appearance.bodyShape)
    setTextures(a, app.sex, app.appearance.textures)
  }

  public applyAppearance() {
    this._applyAppearance(applyBodyShape, applyTextures)
  }

  public applyMuscleDefinition() {
    this._applyAppearance(dontApplyBodyShape, applyTextures)
  }
}
