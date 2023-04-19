import { O } from "Combinators"
import * as Log from "Log"
import { Actor, printConsole } from "skyrimPlatform"
import { defaultArchetype } from "../constants"
import {
  ActorsCfg,
  ClassArchetype,
  ClassMatch,
  MuscleDefinition,
  RacialMatch,
  Sex,
  classArchetype,
  fitStage,
  knownNPCs,
  mcm,
} from "../database"
import { LogE, LogI, LogIT, LogN, LogV, LogVT } from "../debug"
import {
  ApplyBodyslide,
  ApplyMuscleDef,
  ChangeHeadSize,
  ClearAppearance as ClearActorAppearance,
  GetBodyslide,
  GetHeadSize,
  GetMuscleDefTex,
  InterpolateMusDef,
  InterpolateW,
  IsMuscleDefBanned,
} from "./appearance"
import {
  BodyShape,
  BodyslidePreset,
  exportedBstoPreset,
  getBodyShape,
} from "./bodyslide"
import {
  TexturePaths,
  getRaceSignature,
  getTexturePaths,
  getTextures,
  logBanner,
} from "./common"
import { NpcType as NT } from "./npc/calculated"
import { getCached, saveToCache } from "./shared/cache/non_dynamic"
import * as Journeys from "./shared/dynamic/journey/manager"

const Alt = O

/** Raw appearance data shared by both Known and Generic NPCs.
 *
 * @remarks
 * This is intermediate data that will be processed to its final form the same way for both
 * Known and Generic NPCs, but the ways to obtain it are different.
 */
interface RawAppearance {
  /** Body morphs will be gotten from this. */
  fitStageId: number
  /** No muscle definition will be calculated if undefined. */
  muscleDef?: MuscleDefinition
  /** No body morph will be calculated if undefined. */
  weight?: number
}

enum NpcType {
  known,
  generic,
}

interface NpcOptions {
  applyMorphs: boolean
  applyMuscleDef: boolean
}

/** Logs the NPC name banner */
function logNPCBanner(name: string, formID: number) {
  logBanner(`Setting appearance of ${name}`, LogN)
  LogN(`RefID (will be cached): ${formID}`)
}

function applyFromCache(a: Actor, sex: Sex, formID: number): NT | null {
  const cd = getCached(formID)
  if (!cd) return null

  const shape = cd.shape
  const texs = cd.textures

  ApplyBodyslide(a, shape.bodySlide)
  ChangeHeadSize(a, shape.headSize)

  ApplyMuscleDef(a, sex, texs.muscle)
  applySkin(a, sex, texs.skin)

  saveToCache(formID, shape, texs) // NPC was just seen once again

  return NT.cached
}

/** Changes appearance */
function newChangeAppearance(a: Actor | null) {
  if (!a) return

  const d = getActorData(a)
  if (!d) return

  const formID = a.getFormID()
  logNPCBanner(d.name, formID)

  const wasCached = applyFromCache(a, d.sex, formID)
  if (wasCached) return wasCached

  const identity = solveIdentity(d)
  if (!identity) return // The NPC is not valid or known

  const canChange = d.sex === Sex.female ? db.mcm.actors.fem : db.mcm.actors.men
  switch (identity.npcType) {
    case NT.dynamic:
      const dynApp = Journeys.getAppearanceData(
        identity.journey as string,
        identity.race,
        d.race,
        d.sex
      )
      ApplyBodyslide(a, dynApp?.bodyShape?.bodySlide)
      ChangeHeadSize(a, dynApp?.bodyShape?.headSize)

      ApplyMuscleDef(a, d.sex, dynApp?.textures?.muscle)
      applySkin(a, d.sex, dynApp?.textures?.skin)
      break
    case NT.generic:
      const app = getAppearanceData(d, identity.race, identity.archetype)
      const shape = getBodyShape(app)
      const texs = getTextures(app)

      ApplyBodyslide(a, shape.bodySlide)
      ChangeHeadSize(a, shape.headSize)

      ApplyMuscleDef(a, d.sex, texs.muscle)
      applySkin(a, d.sex, texs.skin)

      saveToCache(formID, shape, texs)

      break
    case NT.known:
      const knData = identity.knownData
      if (!knData) return identity.npcType
      LogN(
        `${knData.name} data was already calculated when exporting. Check the configuration app report for more info.`
      )

      const knShape: BodyShape = {
        bodySlide: exportedBstoPreset(knData.bodyslide),
        headSize: knData.head,
      }

      const ts = getTexturePaths(d.race, knData.muscleDef, knData.skin)
      const knTexs: TexturePaths = {
        muscle: ts.muscle,
        skin: ts.skin,
      }

      ApplyBodyslide(a, knShape.bodySlide)
      ChangeHeadSize(a, knData.head)

      ApplyMuscleDef(a, d.sex, ts.muscle)
      applySkin(a, d.sex, ts.skin)

      saveToCache(formID, knShape, knTexs)

      break
  }

  LogN("\n")

  return identity.npcType
}

import { RaceGroup, db } from "../types/exported"
import { applySkin } from "./nioverride/skin"
import { NpcIdentity } from "./npc/calculated"
import { getJourney } from "./npc/dynamic"
import { getAppearanceData, getArchetype } from "./npc/generic"
import { getKnownNPC } from "./npc/known"
import { ActorData, getActorData } from "./shared/ActorData"
// import { getTexturePaths } from "./shared/textures"

//#region Solve appearance

function solveIdentity(d: ActorData) {
  LogI(`Class: ${d.class}`)
  const sig = getRaceSignature(d.race)
  if (!sig) return null

  return getNPCType(d, sig)
}

function getNPCType(d: ActorData, sig: RaceGroup): NpcIdentity {
  LogV(`Getting NPC type`)
  LogV(`Esp: ${d.esp}`)
  LogV(`Fixed FormID: ${d.fixedFormId.toString(16)}`)

  const esp = d.esp.toLowerCase()
  const id = d.fixedFormId.toString()

  const journey = getJourney(esp, id)
  if (journey) {
    LogN(`Has a Fitness Journey: ${journey}`)
    return { npcType: NT.dynamic, journey: journey, race: sig }
  }

  const knData = getKnownNPC(esp, id)
  if (knData) {
    LogN("Is a Known/Explicit NPC")
    return { npcType: NT.known, knownData: knData, race: sig }
  }

  const ar = getArchetype(d)
  if (!ar)
    LogN(
      "No archetype matched this Race/Class combination. NPC will use the default Fitness Stage."
    )
  else LogN(`Archetype: "${db.archetypes[ar.toString()].iName}" (${ar})`)
  return { npcType: NT.generic, archetype: ar, race: sig }
}

//#endregion

/** Changes an NPC appearance according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeAppearance(a: Actor | null) {
  newChangeAppearance(a) // FIX: Move code here
  // if (
  //   tt === NT.generic ||
  //   tt === NT.known ||
  //   tt === NT.cached ||
  //   tt === NT.dynamic
  // ) {
  //   LogN("Hijacking old method")
  //   return // Hijack generic NPC appearance setting
  // }
  // LogN("******************************************************")
  // if (!a) return
  // ApplyAppearance(a, true, true)
  // LogN("******************************************************")
}

/** Changes an NPC muscle definition according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeMuscleDef(a: Actor | null) {
  // ApplyAppearance(a, false, true)
}

/** Removes body morphs and texture overrides to avoid save game bloating.
 * @param a `Actor` to clear their appearance.
 */
export function ClearAppearance(a: Actor | null) {
  try {
    ClearActorAppearance(a)
    LogV(`--- ${NPCDataToStr(getActorData(a))}`)
  } catch (error) {
    LogE(
      "There was an error trying to clear an NPC. This should be benign and no harm should be done."
    )
  }
}

/** Outputs a string with all data needed to debug an NPC.
 *
 * @param d {@link ActorData}
 * @returns A message with all data needed to recognize an NPC while debugging.
 *
 * @remarks
 * "FixedFormId" message is only useful for making sure this mod is correctly finding
 * a known NPC. It's totally useless for leveled NPCs.
 */
function NPCDataToStr(d: ActorData | null): string {
  if (!d) return "Invalid NPC found. This should be harmless."

  return (
    `BaseID: ${Log.IntToHex(d.base.getFormID())} ` +
    `RefId: ${Log.IntToHex(d.actor.getFormID())} ` +
    `FixId: ${d.fixedFormId} ` +
    `${d.esp}|0x${d.fixedFormId.toString(16)}. ` +
    `${d.class}, ` +
    `${d.race}, ` +
    `${Sex[d.sex]}, ` +
    `weight: ${d.weight}, ` +
    `${d.name}`
  )
}
