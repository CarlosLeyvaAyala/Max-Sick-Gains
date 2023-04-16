import { Journey } from "./types"
import { FitJourney, db } from "../../../../types/exported"
import { PlayerJourney } from "../../../player/journey"
import { LogI, LogN, LogVT } from "../../../../debug"
import * as O from "DmLib/typescript/Object"
import { HumanHours, Now, hourSpan } from "DmLib/Time"
import { sendSleep } from "../../../../events/maxick_compatibility"

/** Journey list. */
const journeys: Journey[] = []

/** Creates all Fitness Journey objects that will be used in game.
 * @remarks
 * This need to be called from a Skyrim Platform event because all
 * the needed data to start is not available before them.
 */
export function initialize() {
  LogN("Initializing Fitness Journeys")

  // Player is always the first journey added
  journeys.push(new PlayerJourney("Player", db.fitJourneys["Player"]))

  O.entriesToArray(db.fitJourneys)
    .filter(([k, _]) => k !== "Player")
    .forEach(([k, v]) => journeys.push(new Journey(k, v)))

  journeys.forEach((j) => {
    j.start()
    j.calculateAppearance()
  })
}

export const player = () => journeys[0] as PlayerJourney
export const NPCs = () => journeys.slice(1)

function onSleep(hoursSlept: HumanHours) {
  journeys.forEach((j) => {
    j.advanceStage(hoursSlept)
    j.calculateAppearance()
  })

  sendSleep(hoursSlept)
}

let goneToSleepAt = 0

/** Player went to sleep. */
export function onSleepStart() {
  goneToSleepAt = LogVT("OnSleepStart", Now())
}

/** Player woke up. */
export function onSleepEnd() {
  const p = player()
  const Ls = () => {
    p.lastSlept = LogVT("Awaken at", Now())
  }

  LogN("--- Finished sleeping")

  if (hourSpan(p.lastSlept) < 3) {
    LogN("You just slept. Nothing will be done.")
    Ls()
    return
  }

  const hoursSlept = LogVT("Hours slept", hourSpan(goneToSleepAt))
  if (hoursSlept < 0.8) return // Do nothing. Didn't really slept.
  Ls()
  onSleep(hoursSlept)
}