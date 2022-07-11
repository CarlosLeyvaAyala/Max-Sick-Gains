import { DebugLib as D } from "DmLib"
import { mcm } from "./database"

export const mod_name = "maxick"

const logToConsole = mcm.logging.toConsole
const logToFile = mcm.logging.toFile
const currLogLvl = D.Log.LevelFromValue(mcm.logging.level)

const d = D.Log.CreateAll(
  "Maxick",
  currLogLvl,
  logToConsole ? D.Log.ConsoleFmt : undefined,
  logToFile ? D.Log.FileFmt : undefined
)

/** Logs messages intended to detect bottlenecks. */
export const LogO = d.Optimization

/** Logs an error message. */
export const LogE = d.Error

/** Logs detailed info meant for players to see. */
export const LogI = d.Info

/** Logs detailed info meant only for debugging. */
export const LogV = d.Verbose

/** Logs a variable while initializing it. Message level: info. */
export const LogIT = d.TapI

/** Logs a variable while initializing it. Message level: verbose. */
export const LogVT = d.TapV

export const LogN = d.None

LogN(`Logging level: ${D.Log.Level[currLogLvl]}`)
