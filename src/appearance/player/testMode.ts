import { Debug, printConsole } from "skyrimPlatform"
import { db } from "../../types/exported"
import { ListenTo, fromValue } from "DmLib/Hotkeys"
import { LogI } from "../../debug"
import { PlayerJourney } from "./journey"

const cfg = db.mcm.testingMode
export const enabled = db.mcm.testingMode.enabled
if (enabled) printConsole(`+++ Max Sick Gains: TESTING MODE ENABLED`)

const FO = (k: string) => fromValue(k)
const HK = (k: string) => ListenTo(FO(k), enabled)

/** Gains +10 hotkey listener. */
export const add10 = HK(cfg.hkGainsAdd10)

/** Gains -10 hotkey listener. */
export const sub10 = HK(cfg.hkGainsSub10)

/** Next Stage hotkey listener. */
export const next = HK(cfg.hkNext)

/** Previous Stage hotkey listener. */
export const prev = HK(cfg.hkPrev)

/** Slideshow hotkey listener. */
export const SlideShow = HK(cfg.hkSlideshow)

let slideshowRunning = false
let player: PlayerJourney

export function setup(p: PlayerJourney) {
  player = p
}

function DisplayStageName() {
  Debug.notification(player.welcomeMsg)
}

function LogGainsDelta(delta: number) {
  return () => {
    LogI(`Gains ${delta < 0 ? "" : "+"}${delta}: ${player.gains}`)
  }
}

function ModGains(delta: number) {
  player.testModeSetGains(player.gains + delta)
}

function SetGains(x: number) {
  player.testModeSetGains(x)
  // gains = SGains(x)
  // Sleep.SendJourney()
}

// function ModStage(delta: number) {
//   SetStage(pStage + delta)
// }

// function SetStage(x: number) {
//   pStage = SpStage(CapStage(x))
// }

// export function GoSlideShow() {
//   if (!enabled || slideshowRunning) return
//   LogI("Running Slideshow Mode")
//   SetGains(0)
//   SetStage(0)
//   SendGainsSet(0)
//   Player.Appearance.Change()
//   slideshowRunning = true

//   const run = async () => {
//     Debug.messageBox(
//       "Slideshow mode has started. Now you can see how your character will change with training."
//     )
//     await Utility.wait(2)
//     while (GoModGains(2)) {
//       await Utility.wait(0.1)
//     }
//     await Utility.wait(2)
//     Debug.messageBox("Slideshow has ended")
//     slideshowRunning = false
//   }
//   run()
// }

// function LogStageChange(st: string) {
//   LogI(`Going to ${st} stage (${pStage + 1}/${playerStages.length})`)
// }

// /** Go to next Fitness Stage */
// export function GoNext() {
//   return GoModStage(1, "end", 100, "next", 0)
// }

// /** Go to previous Fitness Stage */
// export function GoPrev() {
//   return GoModStage(-1, "start", 0, "previous", 100)
// }

// /** Changes Player Stage.
//  * @returns Wether it's possible to continue going in the same direction.
//  */
// function GoModStage(
//   delta: number,
//   cantGo: string,
//   cantGoGains: number,
//   chMsg: string,
//   newGains: number
// ) {
//   if (!enabled) return false

//   const old = pStage
//   ModStage(delta)
//   const change = old - pStage

//   let canContinue = true

//   const G = (g: number) => {
//     SetGains(g)
//     LogI(`Gains were adjusted to ${g}`)
//     SendGainsSet(gains)
//   }

//   if (change === 0) {
//     Debug.notification(
//       `You reached the ${cantGo} of your journey. You can't go any further.`
//     )
//     G(cantGoGains)
//     canContinue = false
//   } else {
//     LogStageChange(chMsg)
//     G(newGains)
//     DisplayStageName()
//     canContinue = true
//   }

//   Player.Appearance.Change()
//   return canContinue
// }

// /** Gains +10 */
// export function GoAdd10() {
//   GoModGains(10)
// }

// /** Gains -10 */
// export function GoSub10() {
//   GoModGains(-10)
// }

// function GoModGains(delta: number) {
//   if (!enabled) return
//   ModGains(delta)
//   LogGainsDelta(delta)()
//   SendGainsSet(gains)
//   if (gains > 100) return GoNext()
//   else if (gains < 0) return GoPrev()
//   else Player.Appearance.Change()
//   return true
// }
