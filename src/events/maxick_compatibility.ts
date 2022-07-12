import { Game } from "skyrimPlatform"

// ; !  ██╗  ██╗███████╗██╗     ██████╗ ███████╗██████╗ ███████╗
// ; !  ██║  ██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗██╔════╝
// ; !  ███████║█████╗  ██║     ██████╔╝█████╗  ██████╔╝███████╗
// ; !  ██╔══██║██╔══╝  ██║     ██╔═══╝ ██╔══╝  ██╔══██╗╚════██║
// ; !  ██║  ██║███████╗███████╗██║     ███████╗██║  ██║███████║
// ; !  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝

/**
 * Tells Max Sick Gains the player has slept some hours and it's time to make gains.
 *
 * @param humanHoursSlept How many hours of sleep will be simulated.
 *
 * @remarks
 * Use this to simulate the Player Character has slept, even though the player hasn't
 * used a bed to do so.
 *
 * @example
 * ```
 * // Let's fix the fact that no time passes between going to sleep
 * // and being waked up by Astrid...
 * function whenKidnapped(){
 *   const hoursPassed = 4
 *   advanceTime(hoursPassed)
 *   sendSleep(hoursPassed)
 * }
 * ```
 */
export function sendSleep(humanHoursSlept: number) {
  Game.getPlayer()?.sendModEvent(SLEEP, "", humanHoursSlept)
}

/** Returns whether `Testing Mode` is activated or not. */
export function isInTestingMode(): boolean {
  return cfg.MCM.testingMode.enabled
}

// ; !  ███████╗███████╗███╗   ██╗██████╗      █████╗ ███╗   ██╗██████╗     ██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗
// ; !  ██╔════╝██╔════╝████╗  ██║██╔══██╗    ██╔══██╗████╗  ██║██╔══██╗    ██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝
// ; !  ███████╗█████╗  ██╔██╗ ██║██║  ██║    ███████║██╔██╗ ██║██║  ██║    ██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗
// ; !  ╚════██║██╔══╝  ██║╚██╗██║██║  ██║    ██╔══██║██║╚██╗██║██║  ██║    ██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝
// ; !  ███████║███████╗██║ ╚████║██████╔╝    ██║  ██║██║ ╚████║██████╔╝    ██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗
// ; !  ╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝

// ; You are better off using the functions provided by this file if you want to send these events,
// ; but here's the whole reference, so you know what they do.

/** **Activation**: When leveled up a skill that contributes to training.
 *
 * `strArg`: The skill that went up.
 *
 * - You can send events that count as training, and thus, affecting inactivity.
 * - Make sure to send an [event defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
 */
export const TRAIN = "Maxick_Train"

/** **Activation**: Once `training` and `inactivity` have both been defined and will be sent to being applied on the player.
 *
 * `strArg`: The skill that went up/down. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
 * `numArg`: How much training will be added/substracted.
 *
 * - You can send events that directly affect training without affecting inactivity, so you should send this and `ACTIVITY_CHANGE` in tandem.
 * - Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
 * - This event makes the widget flash.
 */
export const TRAINING_CHANGE = "Maxick_TrainChange"

/** **Activation**: Once `training` and `inactivity` have both been defined and will be sent to being applied on the player.
 *
 * `strArg`: The skill that went up. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
 * `numArg`: How much inactivity will be added/substracted (***HUMAN HOURS***). Send a positive value to simulate training. Negative to simulate inactivity.
 *
 * - You can send events that directly affect `training` without affecting `inactivity`, so you should send this and `TRAINING_CHANGE` in tandem.
 * - Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
 * - This event **DOES NOT** make the widget flash.
 */
export const ACTIVITY_CHANGE = "Maxick_ActivityChange"

/** **Activation**: When gains have been calculated but aren't yet set.
 *
 * `numArg`: The change value for gains. Positive if gained. Negative when lost.
 *
 * - You can send your own values to affect player gains without training.
 * - This event makes the widget flash.
 */
export const GAINS_CHANGE = "Maxick_GainsChange"

/** **Activation**: When woken up.
 *
 * `numArg`: Number of hours slept ***IN HUMAN HOURS***, NOT game time.
 *
 * - You can simulate the player sleeping by sending this event, thus making gains calculations on sleeping.
 */
export const SLEEP = "Maxick_Sleep"

// ; !  ██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗     ██████╗ ███╗   ██╗██╗  ██╗   ██╗
// ; !  ██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝    ██╔═══██╗████╗  ██║██║  ╚██╗ ██╔╝
// ; !  ██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗      ██║   ██║██╔██╗ ██║██║   ╚████╔╝
// ; !  ██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝      ██║   ██║██║╚██╗██║██║    ╚██╔╝
// ; !  ██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗    ╚██████╔╝██║ ╚████║███████╗██║
// ; !  ╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝     ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝

// ; ***NEVER*** SEND THESE EVENTS YOURSELF with `SendModEvent()`.
// ; These aren't meant to be sent by addon creators and you may end up breaking this mod.
// ;
// ; It's completely secure (and encouraged) to listen to these events by using
// ; `RegisterForModEvent()`, though.
// ;
// ; https://www.creationkit.com/index.php?title=RegisterForModEvent_-_Form

/** **Activation**: When `gains` are set.
 *
 * - `float numArg`: Number between `[0..1]`.
 * Average of the total percent of the player journey that the other methods reported.
 *
 * ### Remarks
 *
 * - Use this to know how much the player has advanced towards their fitness goals.
 * - This is the preferred method for gauging player progress.
 *
 * ### Sample usage:
 *
 * ```
 * Event OnJourneyAverage(string _, string __, float journey, Form ___)
 *   Log("Journey average sucessfully got: " + journey)
 * EndEvent
 * ```
 */
export const JOURNEY_AVERAGE = "Maxick_JourneyByAverage"

/** **Activation**: When `gains` are set.
 *
 * `float numArg`: Total percent of the player journey (based on Player Stages).
 *
 * - Use this to know how much the player has advanced towards their fitness goals.
 */
export const JOURNEY_DAYS = "Maxick_JourneyByDays"

/** **Activation**: When `gains` are set.
 *
 *
 * `float numArg`: Total percent of the player journey (based on Player Stages).
 *
 * - Use this to know how much the player has advanced towards their fitness goals.
 */
export const JOURNEY_STAGE = "Maxick_JourneyByStage"

/** **Activation**: When `gains` are set.
 *
 * `float numArg`: The new value for `gains`: `[0..100]`.
 *
 * - Use this for reference. So you can do things based on current `gains`.
 * - This event adjusts the widget value display.
 */
export const GAINS = "Maxick_Gains"

/** **Activation**: When `training` is set.
 * ***This refers to the `training` variable, not the act of training***, which is what `TRAIN` is for.
 *
 * `float numArg`: The new value for `training`: `[0..12]`.
 *
 * - Use this for reference. So you can do things based on current `training`.
 * - This event adjusts the widget value display.
 */
export const TRAINING = "Maxick_Training"

/** **Activation**: When `inactivity` is set.
 *
 * `float numArg`: The new value for `inactivity` `[0..100]`.
 *
 * - This event adjusts the widget value display.
 */
export const INACTIVITY = "Maxick_Inactivity"

/** **Activation**: When a new `playerStage` is set.
 *
 * `int numArg`: How many stages have changed. Negative when regressing.
 *
 * - This event makes the widget to show a message saying that Player Stage has changed.
 */
export const PLAYER_STAGE_DELTA = "Maxick_PlayerStageDelta"

/** **Activation**: When a new `playerStage` is set.
 *
 * `int numArg`: The new Player Stage.
 */
export const PLAYER_STAGE = "Maxick_PlayerStage"

/** **Activation**: When the player enters catabolic state and starts to lose gains.
 *
 * `int numArg = 1`. Use this to manage this event and `CATABOLISM_END` with only one event.
 *
 * - This event tells the widget to flash loses every step (affected by `UPDATE_INTERVAL`).
 */
export const CATABOLISM_START = "Maxick_CatabolismStart"

/** **Activation**: When the player exits catabolic state by training.
 *
 * `numArg = 0`. Use this to manage this event and `CATABOLISM_START` with only one event.
 */
export const CATABOLISM_END = "Maxick_CatabolismEnd"

//;! ██╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗ ███████╗
//;! ██║██╔════╝ ████╗  ██║██╔═══██╗██╔══██╗██╔════╝
//;! ██║██║  ███╗██╔██╗ ██║██║   ██║██████╔╝█████╗
//;! ██║██║   ██║██║╚██╗██║██║   ██║██╔══██╗██╔══╝
//;! ██║╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║███████╗
//;! ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

// Everything below here isn't meant to be directly used by you!
const modName = "maxick"
//@ts-ignore
const cfg = settings[modName]
