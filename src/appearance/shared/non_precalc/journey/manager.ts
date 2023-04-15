import { Journey } from "./types"
import { FitJourney, db } from "../../../../types/exported"
import { PlayerJourney } from "../../../player/journey"
import { LogN } from "../../../../debug"
import * as O from "DmLib/typescript/Object"

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

  journeys.forEach((j) => j.start())
}

export const player = () => journeys[0] as PlayerJourney
export const NPCs = () => journeys.slice(1)
