import { Game } from "skyrimPlatform"

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
  Game.getPlayer()?.sendModEvent("Maxick_CatabolismStart", "", 1)
}

/** Sends an event saying player exited catabolic state.
 *
 * @remarks
 * This event sends a `0` so you can us the same Papyrus event to
 * react to both this and {@link SendCatabolismStart}.
 */
export function SendCatabolismEnd() {
  Game.getPlayer()?.sendModEvent("Maxick_CatabolismEnd", "", 0)
}
