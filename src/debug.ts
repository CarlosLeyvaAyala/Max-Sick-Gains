import { printConsole } from "skyrimPlatform"
import { DebugLib as D } from "DmLib"

export const mod_name = "maxick"

// TODO: Get from settings
const logToConsole = true
const logToFile = true
// D.Log.LevelFromSettings(mod_name, "loggingLevel")
const currLogLvl = D.Log.Level.error

printConsole(`${mod_name} logging level: ${D.Log.Level[currLogLvl]}`)

// Generates a logging function specific to this mod.
const CLF = (logAt: D.Log.Level) =>
  D.Log.CreateFunction(
    currLogLvl,
    logAt,
    "Maxick",
    logToConsole ? D.Log.ConsoleFmt : undefined,
    logToFile ? D.Log.FileFmt : undefined
  )

/** Logs messages intended to detect bottlenecks. */
export const LogO = CLF(D.Log.Level.optimization)

/** Logs an error message. */
export const LogE = CLF(D.Log.Level.error)

/** Logs detailed info meant for players to see. */
export const LogI = CLF(D.Log.Level.info)

/** Logs detailed info meant only for debugging. */
export const LogV = CLF(D.Log.Level.verbose)

/** Logs a variable while initializing it. Message level: info. */
export const LogIT = D.Log.Tap(LogI)

/** Logs a variable while initializing it. Message level: verbose. */
export const LogVT = D.Log.Tap(LogV)
