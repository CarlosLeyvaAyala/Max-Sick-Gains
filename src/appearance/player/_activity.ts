import { Now, SkyrimHours, toHumanHours, toSkyrimHours } from "DmLib/Time"
import { LogN, LogNT, LogV, LogVT } from "../../debug"
import { forceRange } from "DmLib/Math"
import {
  SendCatabolismEnd,
  SendCatabolismStart,
  SendInactivity,
} from "../../events/events_hidden"

const inactiveTimeLim: SkyrimHours = toSkyrimHours(48)

/** Calculates new inactivity when new activity is added.
 *
 * @remarks
 * This function never allows inactivity to get out of bounds, so player can get
 * out of catabolism as soon as any kind of training is done.
 *
 * @param activity Activity value. Send negative values to simulate inactivity.
 */
export function hadActivity(activity: SkyrimHours, lastTrained: SkyrimHours) {
  const now = LogNT("Now", Now())
  LogN(`Last trained before: ${lastTrained}`)
  const Cap = (x: number) => forceRange(now - inactiveTimeLim, now)(x)

  // Make sure inactivity is within acceptable values before updating
  const l = Cap(lastTrained)
  lastTrained = Cap(l + activity)

  LogV(`Last trained after: ${lastTrained}`)
  return lastTrained
}

/** Sends events and does checks needed after inactivity change. */
export function sendActivity(lastTrained: SkyrimHours) {
  LogN("--- Sending activity data")
  const hoursInactive = LogNT("Now", Now()) - LogNT("Last trained", lastTrained)
  LogN(`Hours inactive: ${toHumanHours(hoursInactive)}`)
  const inactivePercent = (hoursInactive / inactiveTimeLim) * 100

  SendInactivity(LogNT("Sending inactivity percent", inactivePercent))
  return inactivePercent
}

/** Checks if player is in catabolic state and sends events accordingly.
 *
 * @param i Inactivity percent.
 */
export function catabolicCheck(i: number, isInCatabolic: boolean) {
  const old = isInCatabolic
  // Don't use 100 due to float and time imprecision
  isInCatabolic = LogNT("isInCatabolic", i >= 99.8)

  if (isInCatabolic != old) {
    LogN("There was a change in catabolic state.")
    if (isInCatabolic) {
      LogN("Entered catabolic state.")
      SendCatabolismStart()
    } else {
      LogN("Got out from catabolic state.")
      SendCatabolismEnd()
    }
  }
  return isInCatabolic
}
