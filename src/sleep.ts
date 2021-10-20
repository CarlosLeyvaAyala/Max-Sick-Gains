import { Utility } from "skyrimPlatform"
import { LogE, LogVT } from "./debug"

let lastSlept = 0
let goneToSleepAt = 0
const Now = Utility.getCurrentGameTime

/** Player went to sleep. */
export function OnSleepStart() {
  goneToSleepAt = LogVT("OnSleepStart", Now())
}

/** Player woke up. */
export function OnSleepEnd() {
  if (Now() - lastSlept < 2) {
    LogE("You just slept. Nothing will be done.")
    lastSlept = LogVT("Awaken at", Now())
    return
  }

  const hoursSlept = LogVT("Time slept", Now() - goneToSleepAt)
  if (hoursSlept < 1) return // Do nothing. Didn't really slept.
  lastSlept = LogVT("Awaken at", Now())
}
