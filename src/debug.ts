import { levelFromValue } from "DmLib/Debug/Log/levelFromValue"
import { createAll } from "DmLib/Debug/Log/createAll"
import { Level } from "DmLib/Debug/Log/types"
import { consoleFmt } from "DmLib/Debug/Log/consoleFmt"
import { fileFmt } from "DmLib/Debug/Log/fileFmt"
import { modName } from "./constants"
import { mcm } from "./database"

const logToConsole = mcm.logging.toConsole
const logToFile = mcm.logging.toFile
const currLogLvl = levelFromValue(mcm.logging.level)

const d = createAll(
  modName,
  currLogLvl,
  logToConsole ? consoleFmt : undefined,
  logToFile ? fileFmt : undefined
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

LogN(`Logging level: ${Level[currLogLvl]}`)
