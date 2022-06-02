import { Game } from "skyrimPlatform"
import {
  CATABOLISM_END,
  CATABOLISM_START,
  JOURNEY_AVERAGE,
  JOURNEY_DAYS,
  JOURNEY_STAGE,
} from "./maxick_compatibility"

/** Sends an event saying gains have been set.
 *
 * @remarks
 * This event doesn't make the widget flash.
 *
 * @param gains New gains.
 */
export function SendGainsSet(gains: number) {
  Game.getPlayer()?.sendModEvent("Maxick_Gains", "", gains)
}

/** Sends an event saying gains have been changed.
 *
 * @remarks
 * This event will make the widget flash.
 *
 * @param delta How much gains changed.
 */
export function SendGainsChange(delta: number) {
  Game.getPlayer()?.sendModEvent("Maxick_GainsChange", "", delta)
}

/** Sends an event saying inactivity has changed.
 *
 * @remarks
 * This event will make the widget flash.
 *
 * @param percent A number going from [`0..100`].
 */
export function SendInactivity(percent: number) {
  Game.getPlayer()?.sendModEvent("Maxick_Inactivity", "", percent)
}

/** Sends an event with current training values.
 *
 * @remarks
 * This event won't make the widget flash.
 *
 * @param training Current training [`0..12`].
 */
export function SendTrainingSet(training: number) {
  Game.getPlayer()?.sendModEvent("Maxick_Training", "", training)
}

/** Sends an event saying there was an increment on training.
 *
 * @remarks
 * This event will make the widget flash.
 *
 * @param delta The amount of change in training.
 */
export function SendTrainingChange(delta: number) {
  Game.getPlayer()?.sendModEvent("Maxick_TrainChange", "", delta)
}

/** Sends an event saying player entered catabolic state.
 *
 * @remarks
 * This event sends a `1` so you can us the same Papyrus event to
 * react to both this and {@link SendCatabolismEnd}.
 */
export function SendCatabolismStart() {
  Game.getPlayer()?.sendModEvent(CATABOLISM_START, "", 1)
}

/** Sends an event saying player exited catabolic state.
 *
 * @remarks
 * This event sends a `0` so you can us the same Papyrus event to
 * react to both this and {@link SendCatabolismStart}.
 */
export function SendCatabolismEnd() {
  Game.getPlayer()?.sendModEvent(CATABOLISM_END, "", 0)
}

/** Sends an event saying the player has completed some percent of
 * their _Fitness Journey_.
 *
 * @param percent Average journey percent. [`0`..`1`].
 */
export function SendJourneyAverage(percent: number) {
  Game.getPlayer()?.sendModEvent(JOURNEY_AVERAGE, "", percent)
}

/** Sends an event saying the player has completed some percent of
 * their _Fitness Journey_.
 *
 * @remarks
 * This Journey completition percent is based on how the Journey
 * chart looks on _Max Sick Gains.exe_. This means the middle of
 * the journey is the middle of the chart.
 *
 * Use this kind of value when the visual representation of the
 * journey is important. For example BaboDialogue appearance
 * integration uses this value.
 *
 * @param percent Journey by days percent. [`0`..`1`].
 */
export function SendJourneyByDays(percent: number) {
  Game.getPlayer()?.sendModEvent(JOURNEY_DAYS, "", percent)
}

/** Sends an event saying the player has completed some percent of
 * their _Fitness Journey_.
 *
 * @param percent Journey by stage percent. [`0`..`1`].
 */
export function SendJourneyByStage(percent: number) {
  Game.getPlayer()?.sendModEvent(JOURNEY_STAGE, "", percent)
}
