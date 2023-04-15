import * as JDB from "JContainers/JDB"
import { LogN } from "../debug"

export type SaveFunc<T> = (key: string, value: T) => void
export type RestoreFunc<T> = (key: string, defaultVal?: T) => T
export type SaveGet<T> = [SaveFunc<T>, RestoreFunc<T>]

export function JDBSaveAdapter<T>(
  f: (path: string, value: T, createMissingKeys?: boolean) => boolean
): SaveFunc<T> {
  return (k, v) => f(k, v, true)
}

/** An object that can save its data to a co-save. */
export abstract class SaverObject {
  private readonly _setFlt: SaveFunc<number>
  private readonly _getFlt: RestoreFunc<number>
  private readonly _setInt: SaveFunc<number>
  private readonly _getInt: RestoreFunc<number>
  private readonly _setBool: SaveFunc<boolean>
  private readonly _getBool: RestoreFunc<boolean>
  private readonly _setStr: SaveFunc<string>
  private readonly _getStr: RestoreFunc<string>

  constructor(
    strF: SaveGet<string>,
    intF: SaveGet<number>,
    fltF: SaveGet<number>,
    boolF: SaveGet<boolean>
  ) {
    this._setBool = boolF[0]
    this._getBool = boolF[1]
    this._setFlt = fltF[0]
    this._getFlt = fltF[1]
    this._setInt = intF[0]
    this._getInt = intF[1]
    this._setStr = strF[0]
    this._getStr = strF[1]
  }

  protected saveFloat(key: string, value: number) {
    this._setFlt(key, value)
    // JDB.solveFltSetter(key, value, true)
  }

  protected saveInt(key: string, value: number) {
    this._setInt(key, value)
    // JDB.solveIntSetter(key, value, true)
  }

  protected saveBool(key: string, value: boolean) {
    // JDB.solveBoolSetter(key, value, true)
    this._setBool(key, value)
  }

  protected saveStr(key: string, value: string) {
    this._setStr(key, value)
  }

  private restoreType<T>(
    key: string,
    defaultVal: T,
    getter: (k: string, defaultVal?: T) => T
  ) {
    LogN(`returned getter (${key}): ${getter(key, defaultVal)}`)
    return getter(key, defaultVal)
  }

  /** Gets value from co-save */
  protected restoreInt(key: string, defaultVal: number = 0) {
    return this.restoreType(key, defaultVal, this._getInt)
    // return this.restoreType<number>(key, defaultVal, JDB.solveInt)
  }

  /** Gets value from co-save */
  protected restoreFloat(key: string, defaultVal: number = 0.0) {
    return this.restoreType(key, defaultVal, this._getFlt)
    // return this.restoreType<number>(key, defaultVal, JDB.solveFlt)
  }

  /** Gets value from co-save */
  protected restoreBool(key: string, defaultVal: boolean = false) {
    return this.restoreType(key, defaultVal, this._getBool)
    // return this.restoreType(key, defaultVal, JDB.solveBool)
  }

  protected restoreStr(key: string, defaultVal: string = "") {
    return this.restoreType(key, defaultVal, this._getStr)
  }

  protected keyExists(key: string) {
    return JDB.hasPath(key)
  }

  /** Restores saved values when object is created. */
  protected abstract restoreVariables(): void
}
