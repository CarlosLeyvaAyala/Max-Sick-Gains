import * as Log from "DmLib/Log"
import { modName } from "./constants"
import { db } from "./types/exported"
// import { mcm } from "./database"

const logToConsole = db.mcm.logging.toConsole
const logToFile = db.mcm.logging.toFile
const currLogLvl = Log.LevelFromValue(db.mcm.logging.level)

const d = Log.CreateAll(
  modName,
  currLogLvl,
  logToConsole ? Log.ConsoleFmt : undefined,
  logToFile ? Log.FileFmt : undefined
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
export const LogNT = d.TapN

LogN(`Logging level: ${Log.Level[currLogLvl]}`)
