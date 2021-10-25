import { IntToHex } from "DM-Lib/Debug"
import { GetFormEspAndId } from "DM-Lib/Misc"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
import { Actor, ActorBase } from "skyrimPlatform"
import { fitStage, Sex } from "../database"
import { LogE, LogV, LogVT } from "../debug"
import {
  ApplyBodyslide,
  ClearAppearance as ClearActorAppearance,
  GetBodyslide,
} from "./appearance"

/** Data needed to solve an NPC appearance. */
interface NPCData {
  /** The `Actor` data per se */
  actor: Actor
  /** The leveled `ActorBase` the NPC belongs to */
  base: ActorBase
  /** Male or female? */
  sex: Sex
  /** TES class. */
  class: string
  /** Esp file where the actor was defined */
  esp: string
  /** FormId of `base` inside its esp file */
  fixedFormId: number
  /** Full name of the NPC */
  name: string
  /** Race EDID for the NPC */
  race: string
  /** NPC weight. [0..100] */
  weight: number
}

export function ChangeAppearance(a: Actor | null) {
  const d = LogVT("+++", GetActorData(a), NPCDataToStr)
  if (!d) return
  const bs = GetBodyslide(fitStage(5), d.sex, d.weight)
  ApplyBodyslide(d.actor, bs)
}

export function ClearAppearance(a: Actor | null) {
  LogV(`--- ${NPCDataToStr(GetActorData(a))}`)
  ClearActorAppearance(a)
}

/**
 * Outputs a string with all data needed to debug an NPC.
 *
 * @param d {@link NPCData}
 * @returns A message with all data needed to recognize an NPC while debugging.
 *
 * @remarks
 * "FixedFormId" message is only useful for making sure this mod is correctly finding
 * a known NPC. It's totally useless for leveled NPCs.
 */
function NPCDataToStr(d: NPCData | null): string {
  if (!d) return "Invalid NPC found. This should be harmless."

  return `BaseID: ${IntToHex(d.base.getFormID())} RefId: ${IntToHex(
    d.actor.getFormID()
  )} FixedFormId: ${d.fixedFormId} ${d.esp}|0x${d.fixedFormId.toString(16)}. ${
    d.class
  }, ${d.race}, ${Sex[d.sex]}, ${d.name}`
}

/**
 * Gets all `Actor` needed data to process them.
 *
 * @param a `Actor` to get data from.
 * @returns All needed data.
 */
function GetActorData(a: Actor | null): NPCData | null {
  if (!a) return null
  const l = a.getLeveledActorBase()
  if (!l) {
    LogE("GetActorData: Couldn't find an ActorBase. Is that even possible?")
    return null
  }

  const ff = GetFormEspAndId(l)

  return {
    actor: a,
    base: l,
    sex: l.getSex(),
    class: l.getClass()?.getName() || "",
    name: l.getName() || "",
    race: GetRaceEDID(a),
    esp: ff.modName,
    fixedFormId: ff.fixedFormId,
    weight: l.getWeight(),
  }
}
