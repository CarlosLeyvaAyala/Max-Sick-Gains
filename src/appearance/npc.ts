import * as Log from "Log"
import { Actor } from "skyrimPlatform"
import { Sex } from "../database"
import { LogE, LogI, LogN, LogV } from "../debug"
import { ClearAppearance as ClearActorAppearance } from "./appearance"
import { BodyShape } from "./bodyslide"
import { TexturePaths, getRaceSignature, logBanner } from "./common"
import {
  ShapeSetter,
  applyBodyShape,
  dontApplyBodyShape,
} from "./nioverride/morphs"
import { TextureSetter, applyTextures } from "./nioverride/textures"
import { NpcType as NT } from "./npc/calculated"
import * as JourneyCache from "./shared/cache/dynamic"
import { getCached, saveToCache } from "./shared/cache/non_dynamic"
import * as Journeys from "./shared/dynamic/journey/manager"

/** Logs the NPC name banner */
function logNPCBanner(name: string, formID: number) {
  logBanner(`Setting appearance of ${name}`, LogI)
  LogI(`RefID (will be cached): ${formID}`)
}

interface ApplyAppearance {
  shape: BodyShape
  textures: TexturePaths
}

function applyFromCache(
  a: Actor,
  d: ActorData,
  formID: number,
  setShape: ShapeSetter,
  setTextures: TextureSetter
): NT | null {
  const cd = getCached(formID)
  if (cd)
    return applyNonDynamicCache(formID, a, d.sex, cd, setShape, setTextures)

  const jc = JourneyCache.get(formID)
  if (jc) return applyDynamicCache(formID, a, d, jc, setShape, setTextures)
  return null
}

function applyNonDynamicCache(
  formID: number,
  a: Actor,
  sex: Sex,
  cd: ApplyAppearance,
  setShape: ShapeSetter,
  setTextures: TextureSetter
) {
  const shape = cd.shape
  const texs = cd.textures

  setShape(a, shape)
  setTextures(a, sex, texs)

  saveToCache(formID, shape, texs) // NPC was just seen once again
  LogI("\n")

  return NT.cached
}

function applyDynamicCache(
  formID: number,
  a: Actor,
  d: ActorData,
  c: JourneyCache.CachedNPC,
  setShape: ShapeSetter,
  setTextures: TextureSetter
) {
  const app = Journeys.getAppearanceData(c.key, c.raceGroup, d.race, d.sex)
  if (!app) return null

  setShape(a, app.bodyShape)
  setTextures(a, d.sex, app.textures)

  JourneyCache.save(formID, c.key, c.raceGroup)
  LogI("\n")

  return NT.cached
}

/** Changes appearance */
function newChangeAppearance(
  a: Actor | null,
  setShape: ShapeSetter,
  setTextures: TextureSetter
) {
  if (!a) return

  const d = getActorData(a)
  if (!d) return

  const formID = a.getFormID()
  logNPCBanner(d.name, formID)

  const wasCached = applyFromCache(a, d, formID, setShape, setTextures)
  if (wasCached) return wasCached

  const identity = solveIdentity(d)
  if (!identity) return // The NPC is not valid or known

  const canChange = d.sex === Sex.female ? db.mcm.actors.fem : db.mcm.actors.men

  const app = getAppearanceData(formID, identity, d)

  setShape(a, canChange.applyMorphs ? app?.bodyShape : undefined)
  setTextures(a, d.sex, canChange.applyMuscleDef ? app?.textures : undefined)
  app?.saveToCache()

  LogI("\n")

  return identity.npcType
}
export function getAppearanceData(
  formID: number,
  identity: NpcIdentity,
  d: ActorData
): ApplyAppearanceData | null {
  switch (identity.npcType) {
    case NT.dynamic:
      return DynamicNPC.getAppearanceData(formID, identity, d)
    case NT.generic:
      return GenericNPC.getAppearanceData(formID, identity, d)
    case NT.known:
      return KnownNPC.getAppearanceData(formID, identity, d)
  }
  return null
}

import { RaceGroup, db } from "../types/exported"
import { NpcIdentity } from "./npc/calculated"
import * as DynamicNPC from "./npc/dynamic"
import * as GenericNPC from "./npc/generic"
import * as KnownNPC from "./npc/known"
import { ActorData, getActorData } from "./shared/ActorData"
import { ApplyAppearanceData } from "./shared/appearance"
import { isCurrentFollower } from "DmLib/Actor"

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

  const journey = DynamicNPC.getJourney(esp, id)
  if (journey) {
    LogI(`Has a Fitness Journey: ${journey}`)
    return { npcType: NT.dynamic, journey: journey, race: sig }
  }

  const knData = KnownNPC.get(esp, id)
  if (knData) {
    LogI("Is a Known/Explicit NPC")
    return { npcType: NT.known, knownData: knData, race: sig }
  }

  const ar = GenericNPC.getArchetype(d)
  if (!ar)
    LogV(
      "No archetype matched this Race/Class combination. NPC will use the default Fitness Stage."
    )
  else LogI(`Archetype: "${db.archetypes[ar.toString()].iName}" (${ar})`)
  return { npcType: NT.generic, archetype: ar, race: sig }
}

//#endregion

/** Changes an NPC appearance according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeAppearance(a: Actor | null) {
  newChangeAppearance(a, applyBodyShape, applyTextures)
}

/** Changes an NPC muscle definition according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeMuscleDef(a: Actor | null) {
  newChangeAppearance(a, dontApplyBodyShape, applyTextures)
}

/** Removes body morphs and texture overrides to avoid save game bloating.
 * @param a `Actor` to clear their appearance.
 */
export function ClearAppearance(a: Actor | null) {
  try {
    if (isCurrentFollower(a)) return // Don't clean followers to avoid them not getting their bodies applied

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
