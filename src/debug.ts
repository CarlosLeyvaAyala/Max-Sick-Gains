import * as D from "DM-Lib/Debug"

export const mod_name = "maxick"

const LogConsole: D.LogFormat = (_, __, n, ___, msg) => `[${n}]: ${msg}`

const LogFile: D.LogFormat = (_, m, __, t, msg) =>
  `[${D.LoggingLevel[m]}] ${t.toLocaleString()}: ${msg}`

// TODO: Get from settings
const logToConsole = true
const logToFile = true
// D.ReadLoggingFromSettings(mod_name, "loggingLevel"),
const currLogLvl = D.LoggingLevel.verbose

// Generates a logging function specific to this mod.
const CLF = (logAt: D.LoggingLevel) =>
  D.CreateLoggingFunctionEx(
    currLogLvl,
    logAt,
    "Maxick",
    logToConsole ? LogConsole : undefined,
    logToFile ? LogFile : undefined
  )

/** Logs messages intended to detect bottlenecks. */
export const LogO = CLF(D.LoggingLevel.optimization)

/** Logs an error message. */
export const LogE = CLF(D.LoggingLevel.error)

/** Logs detailed info meant for players to see. */
export const LogI = CLF(D.LoggingLevel.info)

/** Logs detailed info meant only for debugging. */
export const LogV = CLF(D.LoggingLevel.verbose)

/** Logs a variable while initializing it. Message level: info. */
export const LogIT = D.TapLog(LogI)

/** Logs a variable while initializing it. Message level: verbose. */
export const LogVT = D.TapLog(LogV)
