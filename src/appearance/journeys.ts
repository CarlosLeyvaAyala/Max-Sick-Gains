import { storage } from "skyrimPlatform"
import { SaverObject } from "../types/saving"

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

  private _gains = 0
  private _stage = 0

  /** Current gains */
  get gains() {
    return this._gains
  }
  set gains(v) {
    this._gains = v
    this.saveFloat(this.gainsKey, this._gains)
  }

  /** Current stage in its Journey */
  get stage() {
    return this._stage
  }
  set stage(v) {
    this._stage = v
    this.saveInt(this.stageKey, this._stage)
  }

  constructor(key: string) {
    super()
    this.modKey = (v: string) => `.maxickVars.${key}${v}`
    this.gainsKey = this.modKey("gains")
    this.stageKey = this.modKey("stage")
    this.initOrGetHotReloadValues()
  }
}

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

  constructor(key: string) {
    super(key)
    this.trainingKey = this.modKey("training")
    this.lastTrainedKey = this.modKey("lastTrained")
  }

  protected initOrGetHotReloadValues() {
    super.initOrGetHotReloadValues()

    this._training = storage[this.trainingKey] as number | 0
    this._lastTrained = storage[this.lastTrainedKey] as number | 0
  }
}
