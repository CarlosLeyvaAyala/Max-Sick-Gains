import { Actor, hooks, on, printConsole, settings } from "skyrimPlatform"

export interface FitStage {
  iName: string
  muscleDefType: number
}

const modName = "maxick"
const fitStages = settings[modName]["fitStages"]

export function fitStage(id: number) {
  // @ts-ignore
  return fitStages[id.toString()] as FitStage
}
