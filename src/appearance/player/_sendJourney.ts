import { LinCurve, forcePercent } from "DmLib/Math"
import { LogIT, LogN, LogNT } from "../../debug"
import {
  SendJourneyAverage,
  SendJourneyByDays,
  SendJourneyByStage,
} from "../../events/events_hidden"
import { FitJourney } from "../../types/exported"

export function sendJourney(gains: number, stage: number, journey: FitJourney) {
  const gainsP = gains / 100
  const st = journeyByStage(gainsP, stage, journey)
  const days = journeyByDays(gainsP, stage, journey)
  const avg = LogNT("Journey average", (st + days) / 2)

  SendJourneyAverage(avg)
  SendJourneyByDays(days)
  SendJourneyByStage(st)
}

const FP = forcePercent

function journeyByStage(gainsP: number, stage: number, journey: FitJourney) {
  const v = LinCurve(
    { x: 0, y: 0 },
    { x: journey.stages.length, y: 1 }
  )(stage + gainsP)
  return LogNT("Journey by stage", FP(v))
}

function journeyByDays(gainsP: number, stage: number, journey: FitJourney) {
  LogN("Calculating journey by days")

  const pastDays = journey.durations[stage] // Precalculated by Maxick App
  const c = LogNT(
    "Current stage days passed",
    journey.stages[stage].minDays * gainsP
  )

  const r =
    LogNT("Days passed", pastDays + c) /
    LogNT("Total days", journey.totalDuration)

  return LogIT("Journey by days", FP(r))
}
