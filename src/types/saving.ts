import { JContainersToPreserving } from "DmLib/Misc/JContainersToPreserving"
import { preserveVar } from "DmLib/Misc/preserveVar"
import * as JDB from "JContainers/JDB"

/** An object that can save its data to a JDB. */
export abstract class SaverObject {
  private readonly _saveFlt = JContainersToPreserving(JDB.solveFltSetter)
  private readonly _saveInt = JContainersToPreserving(JDB.solveIntSetter)
  private readonly _saveBool = JContainersToPreserving(JDB.solveBoolSetter)

  protected saveFloat(key: string, value: number) {
    preserveVar(this._saveFlt, key)(value)
  }

  protected saveInt(key: string, value: number) {
    preserveVar(this._saveInt, key)(value)
  }

  protected saveBool(key: string, value: boolean) {
    preserveVar(this._saveBool, key)(value)
  }
}
