import { LinCurve, forceRange } from "DmLib/Math"
import { LogN, LogNT, LogV, LogVT } from "../../debug"
import { db } from "../../types/exported"
import { SendTrainingChange, SendTrainingSet } from "../../events/events_hidden"

/** How much `training` is lost a day when in _Catabolic State_. Absolute value. */
const trainCat = 1.8
/** How much `gains` are lost a day when in _Catabolic State_. */
const gainsCat = 0.8

const maxAllowedTraining = 12

/** How much training is lost a day (percent).
 * @remarks
 * Training decay is dynamically calculated to allow a smoother playstyle.
 *
 * When `training >= 10`, returns `20%`. When `training == 0` returns `5%`.
 * Interpolates between those values. */
function dynDecay(training: number) {
  const lD = db.mcm.training.decayMin
  const hD = db.mcm.training.decayMax
  const trainUpperLim = 10
  const cappedTrain = forceRange(0, trainUpperLim)(training)
  return LinCurve({ x: 0, y: lD }, { x: trainUpperLim, y: hD })(cappedTrain)
}

/** Decay and losses calculation */
export function decay(
  td: number,
  training: number,
  isInCatabolic: boolean,
  maxGainsPerDay: number
) {
  LogV("--- Decay")
  const decayRate = dynDecay(training)
  const PollAdjust = (x: number) => td * x * training
  const Catabolism = (x: number) => (isInCatabolic ? PollAdjust(x) : 0)

  /** Training decays all the time. No matter what. */
  const trainD = LogVT("Training decay", PollAdjust(decayRate))

  // Catabolism calculations
  const trainC = LogVT("Training catabolism", Catabolism(trainCat))
  const gainsC = Catabolism(maxGainsPerDay * gainsCat)
  LogV(`Gains catabolism: ${gainsC}`)

  return {
    trainDecay: trainD,
    trainCatabolism: trainC,
    gainsCatabolism: gainsC,
  }
}

const CapTraining = forceRange(0, maxAllowedTraining)

/** Sets training according to some `delta` and sends events telling training changed.
 *
 * @param delta How much the training will change.
 * @param flash Wheter the widget will flash when calculating this.
 */
export function hadTraining(
  training: number,
  delta: number,
  flash: boolean = true
) {
  const r = CapTraining(training + delta)

  SendTrainingSet(r)
  if (flash) SendTrainingChange(delta)
  return r
}
