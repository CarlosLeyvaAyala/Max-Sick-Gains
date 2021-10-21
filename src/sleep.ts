import { HourSpan, HumanHours, Now } from "DM-Lib/Time"
import { Game, printConsole } from "skyrimPlatform"
import { LogE, LogV, LogVT } from "./debug"

let lastSlept = 0
let goneToSleepAt = 0

/** Player went to sleep. */
export function OnSleepStart() {
  goneToSleepAt = LogVT("OnSleepStart", Now())
}

/** Player woke up. */
export function OnSleepEnd() {
  printConsole("Sleep end")
  const Ls = () => LogVT("Awaken at", Now())

  if (HourSpan(lastSlept) < 0.2) {
    LogE("You just slept. Nothing will be done.")
    lastSlept = Ls()
    return
  }

  const hoursSlept = LogVT("Time slept", HourSpan(goneToSleepAt))
  if (hoursSlept < 1) return // Do nothing. Didn't really slept.
  lastSlept = Ls()
  SleepEvent(hoursSlept)
}

function SleepEvent(hoursSlept: HumanHours) {
  Game.getPlayer()?.sendModEvent("Sleep", "", hoursSlept)
  LogV("Calculating player appearance")
}
