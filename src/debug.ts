import * as D from "DM-Lib/Debug"

export const mod_name = "maxick"

// Generates a logging function specific to this mod.
const CLF = (logAt: D.LoggingLevel) =>
  D.CreateLoggingFunction(
    "Maxick",
    // D.ReadLoggingFromSettings(mod_name, "loggingLevel"),
    D.LoggingLevel.verbose,
    logAt
  )

/** Logs messages intended to detect bottlenecks. */
export const LogO = CLF(D.LoggingLevel.optimization)

/** Logs an error message. */
export const LogE = CLF(D.LoggingLevel.error)

/** Logs detailed info meant for players to see. */
export const LogI = CLF(D.LoggingLevel.info)

/** Logs detailed info meant only for debugging. */
export const LogV = CLF(D.LoggingLevel.verbose)

/** Logs a variable while initializing it. Message level: verbose. */
export const LogVT = D.TapLog(LogV)
