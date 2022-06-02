import { Game } from "skyrimPlatform"
import * as JDB from "JContainers/JDB"

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

/** Sends an event saying gains have been change.
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

/** Sends an event saying the player has completed some percent of
 * their _Fitness Journey_.
 *
 * @param x Average journey percent. [`0`..`1`].
 */
export function SendJourneyAverage(x: number) {
  SendFlt("JourneyByAverage", "journeyAvg", x)
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
 * @param x Journey by days percent. [`0`..`1`].
 */
export function SendJourneyByDays(x: number) {
  SendFlt("JourneyByDays", "journeyDays", x)
}

/** Sends an event saying the player has completed some percent of
 * their _Fitness Journey_.
 *
 * @param x Journey by stage percent. [`0`..`1`].
 */
export function SendJourneyByStage(x: number) {
  SendFlt("JourneyByStage", "journeyStage", x)
}

/** Sends a float value to other mods using {@link SendValue}.
 *
 * @param evt Event name.
 * @param key Key used for passing values to other SP plugins via JContainers.
 * @param val Value to pass.
 */
function SendFlt(evt: string, key: string, val: number) {
  SendValue(evt, key, val, JDB.solveFltSetter)
}

/** Sends a value through an event and saves it to JDB.
 *
 * @remarks
 * A Papyrus script can react just by subscribing to the `evt`,
 * but Skyrim Platform plugins need to retrieve event parameters
 * using JDB.
 *
 * @param evt Event name.
 * @param key Key used for passing values to other SP plugins via JContainers.
 * @param val Value to pass.
 * @param Setter JContainers DB function.
 */
function SendValue<T extends string | number>(
  evt: string,
  key: string,
  val: T,
  Setter: (path: string, value: T, create: boolean) => void
) {
  Setter(`.maxickEv.${key}`, val, true)
  const str = typeof val === "string" ? val : ""
  const num = typeof val === "number" ? val : 0
  Game.getPlayer()?.sendModEvent(`Maxick_${evt}`, str, num)
}
