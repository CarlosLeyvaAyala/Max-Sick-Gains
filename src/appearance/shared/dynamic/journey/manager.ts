import { HumanHours, Now, hourSpan } from "DmLib/Time"
import * as O from "DmLib/typescript/Object"
import { LogN, LogNT, LogVT } from "../../../../debug"
import { sendSleep } from "../../../../events/maxick_compatibility"
import { db, playerJourneyKey as pk } from "../../../../types/exported"
import { PlayerJourney } from "../../../player/journey"
import { Journey } from "./types"

/** Journey list. */
let journeys: Map<string, Journey>

/** Creates all Fitness Journey objects that will be used in game.
 * @remarks
 * This need to be called from a Skyrim Platform event because all
 * the needed data to start is not available before them.
 */
export function initialize() {
  journeys = new Map()
  LogN("Initializing Fitness Journeys")

  // Player is always the first journey added
  journeys.set(pk, new PlayerJourney(pk, db.fitJourneys[pk]))

  O.entriesToArray(db.fitJourneys)
    .filter(([k, _]) => k !== pk)
    .forEach(([k, v]) => journeys.set(k, new Journey(k, v)))

  journeys.forEach((j) => {
    j.start()
    j.calculateAppearance()
  })
}

export const player = () => journeys.get(pk) as PlayerJourney

/** Calculations made on Journeys when sleeping */
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
    p.lastSlept = LogNT("Awaken at", Now())
  }

  LogN("--- Finished sleeping")

  if (hourSpan(p.lastSlept) < 3) {
    LogN("You just slept. Nothing will be done.")
    Ls()
    return
  }

  const hoursSlept = hourSpan(goneToSleepAt)
  if (hoursSlept < 0.8) return // Do nothing. Didn't really slept.
  Ls()
  onSleep(LogNT("Hours slept", Math.round(hoursSlept)))
}
