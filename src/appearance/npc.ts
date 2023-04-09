import { BodyShape, getBodyShape, exportedBstoPreset } from "./bodyslide"
import { O } from "DmLib/Combinators/O"
import { R as LogR } from "DmLib/Log/R"
import { intToHex } from "DmLib/Debug/Log/intToHex"
import { getEspAndId } from "Dmlib/Form/uniqueId"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
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
  ApplySkin,
  ChangeHeadSize,
  ClearAppearance as ClearActorAppearance,
  GetBodyslide,
  GetHeadSize,
  GetMuscleDefTex,
  InterpolateMusDef,
  InterpolateW,
  IsMuscleDefBanned,
} from "./appearance"
// import { BodyslidePreset, getTexturePaths } from "./nioverride/common"
import {
  BodyslidePreset,
  getRaceSignature,
  getTexturePaths,
  getTextures,
} from "./common"
import { NpcType as NT, canApplyChanges } from "./npc/calculated"

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

/** Final appearance data for an `Actor`.
 *
 * @remarks
 * If any of these variable is missing, no muscle definition/body morph will be applied.
 */
interface Appearance {
  /** Path to the texture file that will be applied. */
  path?: string
  /** Processed Bodyslide preset. */
  bodyslide?: BodyslidePreset
  /** May be undefined if no morph will be applied. */
  headSize?: number
}

interface CachedAppearance {
  sex: Sex
  race: string
  class: string
  appearance: Appearance
}

interface Cache {
  npcs: { [key: number]: CachedAppearance }
}

const cache: Cache = { npcs: {} }

enum NpcType {
  known,
  generic,
}

interface NpcOptions {
  applyMorphs: boolean
  applyMuscleDef: boolean
}

/** Changes appearance */
function newChangeAppearance(a: Actor | null) {
  if (!a) return
  const d = GetActorData(a)
  if (!d) return

  const identity = solveIdentity(d)
  if (!identity) return // The NPC is not valid or known

  const canChange = canApplyChanges(d, identity)
  switch (identity.npcType) {
    case NT.generic:
      const app = getAppearanceData(d, identity.race, identity.archetype)

      const shape = getBodyShape(app)
      ApplyBodyslide(a, shape.bodySlide)
      ChangeHeadSize(a, shape.headSize)

      const texs = getTextures(app)
      ApplyMuscleDef(a, d.sex, texs.muscle)
      applySkin(a, d.sex, texs.skin)

      break
    case NT.known:
      const knData = identity.knownData
      if (!knData) return identity.npcType
      LogN(
        `${knData.name} data was already calculated when exporting. Check the configuration app report for more info.`
      )
      ApplyBodyslide(a, exportedBstoPreset(knData.bodyslide))
      ChangeHeadSize(a, knData.head)

      const ts = getTexturePaths(d.race, knData.muscleDef, knData.skin)
      ApplyMuscleDef(a, d.sex, ts.muscle)
      applySkin(a, d.sex, ts.skin)

      break
  }

  LogN("\n")

  return identity.npcType
}

import { NPCData, NpcIdentity } from "./npc/calculated"
import { getJourney } from "./npc/dynamic"
import { getAppearanceData, getArchetype } from "./npc/generic"
import { getKnownNPC } from "./npc/known"
import { RaceGroup, db } from "../types/exported"
import { getMuscleDefTexName } from "./appearance"
import { getSkinTexName } from "./appearance"
import { applySkin } from "./nioverride/skin"

//#region Solve appearance

function solveIdentity(d: NPCData) {
  LogN("================================")
  LogN(`Setting appearance of ${d.name}`)
  LogN("================================")
  LogN(`Class: ${d.class}`)
  const sig = getRaceSignature(d.race)
  if (!sig) return null

  return getNPCType(d, sig)
}

function getNPCType(d: NPCData, sig: RaceGroup): NpcIdentity {
  LogN(`Getting NPC type`)
  LogN(`Esp: ${d.esp}`)
  LogN(`Fixed FormID: ${d.fixedFormId.toString(16)}`)

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
  const tt = newChangeAppearance(a) // TODO: Delete this
  if (tt === NT.generic || tt === NT.known) return // Hijack generic NPC appearance setting
  if (!a) return
  ApplyAppearance(a, true, true)
}

/** Changes an NPC muscle definition according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeMuscleDef(a: Actor | null) {
  ApplyAppearance(a, false, true)
}

function AddToCache(d: NPCData, appearance: Appearance) {
  if (!cache.npcs[d.formID])
    cache.npcs[d.formID] = {
      sex: Sex.undefined,
      class: "",
      race: "",
      appearance: {},
    }
  cache.npcs[d.formID].appearance = appearance
  cache.npcs[d.formID].class = d.class
  cache.npcs[d.formID].race = d.race
  cache.npcs[d.formID].sex = d.sex
}

function GetCached(d: NPCData): Appearance | null {
  printConsole("Get chaced++++++++++")
  const c = cache.npcs[d.formID]
  printConsole("c", c)
  if (!c || c.sex !== d.sex || c.race !== d.race || c.class !== d.class)
    return null
  return c.appearance
}

function ApplyAppearance(
  a: Actor | null,
  applyBs: boolean,
  applyMuscleDef: boolean
) {
  const d = LogIT("+++", GetActorData(a), NPCDataToStr)
  if (!d) return

  const r = SolveAppearance(d, mcm.actors)
  // AddToCache(d, r)

  if (applyBs) {
    if (r.bodyslide) ApplyBodyslide(d.actor, r.bodyslide)
    if (r.headSize) ChangeHeadSize(d.actor, r.headSize)
  }
  if (applyMuscleDef) ApplyMuscleDef(d.actor, d.sex, r.path)
}

/** Removes body morphs and texture overrides to avoid save game bloating.
 * @param a `Actor` to clear their appearance.
 */
export function ClearAppearance(a: Actor | null) {
  try {
    ClearActorAppearance(a)
    LogV(`--- ${NPCDataToStr(GetActorData(a))}`)
  } catch (error) {
    LogE(
      "There was an error trying to clear an NPC. This should be benign and no harm should be done."
    )
  }
}

/** Invalid raw appearance */
const iRawApp = { fitStageId: -1 }

const InvalidRace = (d: NPCData) => {
  const id = intToHex(d.actor.getFormID())
  LogI(`NPC 0x${id} does not belong to any known racial group.`)
}

const NothingToDo = (s: Sex, t: NpcType) => {
  LogI(
    `All options for ${NpcType[t]} ${Sex[s]} NPCs are disabled. Nothing to do.`
  )
}

const NoBs = (s: Sex, t: NpcType) => {
  LogI(
    `Body morphs for ${NpcType[t]} ${Sex[s]} NPCs are disabled. Body shape won't change.`
  )
}

const NoMdef = (s: Sex, t: NpcType) => {
  LogI(
    `Muscle definition for ${NpcType[t]} ${Sex[s]} NPCs is disabled; it won't be changed.`
  )
}

/** Gets appearance data for an `Actor`.
 * @param a `Actor` to get their appearance.
 * @returns Fitness stage, muscle definition and adjusted weight according to their Class Archetype.
 */
function SolveAppearance(d: NPCData, o: ActorsCfg): Appearance {
  // const cached = GetCached(d)
  // if (cached) {
  //   printConsole(`Actor got from cache. ${NPCDataToStr(d)}`)
  //   return cached
  // }

  const raceGroup = RacialMatch(d.race)
  if (!raceGroup) return LogR(InvalidRace(d), {}) // Get out and log

  // If it's not a Known NPC, it's a generic one.
  const raw = Alt(SolveKnownNPC, SolveGenericNPC)(d, o)

  const md = IsMuscleDefBanned(d.race) ? undefined : raw.muscleDef
  const fs = fitStage(raw.fitStageId)
  return {
    bodyslide:
      raw.weight !== undefined
        ? GetBodyslide(fs, d.sex, LogIT("Applied weight", raw.weight))
        : undefined,
    path: md ? GetMuscleDefTex(d.sex, raceGroup, md.type, md.level) : undefined,
    headSize:
      raw.weight === undefined
        ? undefined
        : LogVT("Applied head size", GetHeadSize(fs, d.sex, raw.weight)),
  }
}

function SolveKnownNPC(d: NPCData, o: ActorsCfg): RawAppearance | null {
  const esp = knownNPCs[d.esp.toLowerCase()]
  if (!esp) return null
  const kn = esp[d.fixedFormId]
  if (!kn) return null

  LogI(`*** Known NPC found ***: ${d.name}`)
  const s = d.sex
  const t = NpcType.known

  const oo = GetNpcOptions(s, t, o)
  if (!oo.applyMuscleDef && !oo.applyMorphs)
    return LogR(NothingToDo(s, t), iRawApp) // Get out and log

  const mt = fitStage(kn.fitStage).muscleDefType
  return {
    fitStageId: kn.fitStage,
    weight:
      kn.weight === -1
        ? LogR(LogV("Body morphs were disabled for this NPC."), undefined)
        : !oo.applyMorphs
        ? LogR(NoBs(s, t), undefined)
        : kn.weight === 101
        ? d.weight
        : kn.weight,
    muscleDef:
      kn.muscleDef === -1
        ? LogR(LogV("Muscle definition was disabled for this NPC."), undefined)
        : !oo.applyMuscleDef
        ? LogR(NoMdef(s, t), undefined)
        : kn.muscleDef === 0
        ? { level: InterpolateMusDef(1, 6, d.weight), type: mt }
        : { level: kn.muscleDef, type: mt },
  }
}

//#region Generic NPC solving

/** Gets the {@link RawAppearance} of a Generic NPC.
 *
 * @param d {@link NPCData}
 */
function SolveGenericNPC(d: NPCData, o: ActorsCfg): RawAppearance {
  const s = d.sex
  const t = NpcType.generic

  const oo = GetNpcOptions(s, t, o)
  if (!oo.applyMuscleDef && !oo.applyMorphs)
    return LogR(NothingToDo(s, t), iRawApp) // Get out and log

  const arch = Alt(SolveArchetype, DefaultArchetype)(d)
  LogI(`Selected archetype: ${arch.iName}`)

  const fixedW = InterpolateW(arch.bsLo, arch.bsHi, d.weight)

  return {
    fitStageId: arch.fitStage,
    weight: oo.applyMorphs ? fixedW : LogR(NoBs(s, t), undefined),
    muscleDef: oo.applyMuscleDef
      ? {
          level: InterpolateMusDef(arch.muscleDefLo, arch.muscleDefHi, fixedW),
          type: fitStage(arch.fitStage).muscleDefType,
        }
      : LogR(NoMdef(s, t), undefined),
  }
}

/** Gets the best Class Archetype for an NPC.
 *
 * @param d {@link NPCData}
 * @returns A {ClassArchetype}. `null` if none was found.
 */
function SolveArchetype(d: NPCData): ClassArchetype | null {
  const archs = LogVT(
    "All possible unfiltered archetypes",
    ClassMatch(d.name, d.class)
  )
  let exclusive: ClassArchetype[] = []
  let nonExclusive: ClassArchetype[] = []
  archs.forEach((v, _, __) => {
    FilterViableArchetypes(classArchetype(v), d, exclusive, nonExclusive)
  })

  if (exclusive.length > 0) return SelectArchetype(exclusive)
  else if (nonExclusive.length > 0) return SelectArchetype(nonExclusive)
  return null // Will need to get a default archetype
}

/** Selects only one element from a list of Class Archetypes.
 *
 * @param arr An array of {@link ClassArchetype}.
 * @returns Only one `ClassArchetype`.
 */
function SelectArchetype(arr: ClassArchetype[]) {
  const names = arr.map((v, _, __) => v.iName).join(", ")
  LogV(`Viable archetypes: ${names}`)
  if (arr.length > 1) {
    return arr[arr.length - 1]
  } else return arr[0]
}

/** Gets all viable Class Archetypes for an NPC.
 *
 * @remarks
 * This function discards archetypes that have weight and racial constraints
 * the NPC doesn't match.
 *
 * It sends the resulting archetypes to two different arrays: one containing all
 * class archetypes where the NPC race matches. The other contains the rest of them.
 *
 * @param {ClassArchetype} ar Archetype to test.
 * @param {NPCData} d NPC data.
 * @param {ClassArchetype[]} exclusive Array containing all archetypes where the NPC has race exclusiveness.
 * @param {ClassArchetype[]} nonExclusive Array with all non exclusive archetype the NPC matched.
 */
function FilterViableArchetypes(
  ar: ClassArchetype,
  d: NPCData,
  exclusive: ClassArchetype[],
  nonExclusive: ClassArchetype[]
) {
  const WeightOutOfBounds = (w: number) => w < ar.weightLo || w > ar.weightHi
  if (WeightOutOfBounds(d.weight)) return

  if (ar.raceExclusive.length === 0) {
    nonExclusive.push(ar)
    return
  }
  const race = d.race.toLowerCase()
  if (ar.raceExclusive.some((r, _) => race.indexOf(r) >= 0)) exclusive.push(ar)
}

const DefaultArchetype = (_: NPCData) => defaultArchetype

//#endregion

/** Returns "MCM" options for an NPC, according to their sex and type.
 * @param  {Sex} s
 * @param  {NpcType} t
 * @param  {ActorsCfg} o
 * @returns NpcOptions
 */
function GetNpcOptions(s: Sex, t: NpcType, o: ActorsCfg): NpcOptions {
  if (s === Sex.female) return t === NpcType.known ? o.knownFem : o.genericFem
  return t === NpcType.known ? o.knownMan : o.genericMan
}

/** Outputs a string with all data needed to debug an NPC.
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

  return (
    `BaseID: ${intToHex(d.base.getFormID())} ` +
    `RefId: ${intToHex(d.actor.getFormID())} ` +
    `FixId: ${d.fixedFormId} ` +
    `${d.esp}|0x${d.fixedFormId.toString(16)}. ` +
    `${d.class}, ` +
    `${d.race}, ` +
    `${Sex[d.sex]}, ` +
    `weight: ${d.weight}, ` +
    `${d.name}`
  )
}

/** Gets all `Actor` needed data to process them.
 *
 * @param a `Actor` to get data from.
 * @returns All needed data.
 */
function GetActorData(a: Actor | null): NPCData | null {
  if (!a) return null

  try {
    const l = a.getLeveledActorBase()
    const b = a.getBaseObject()
    if (!l || !b) {
      LogE("GetActorData: Couldn't find an ActorBase. Is that even possible?")
      return null
    }

    // Using base because esp getting fails for leveled actors
    const { modName, fixedFormId } = getEspAndId(b)

    return {
      actor: a,
      base: l,
      sex: l.getSex(),
      class: l.getClass()?.getName() || "",
      name: l.getName() || "",
      race: GetRaceEDID(a),
      esp: modName,
      fixedFormId: fixedFormId,
      weight: l.getWeight(),
      formID: a.getFormID(),
    }
  } catch (error) {
    LogE(
      "There was an error trying to get the NPC data. This rarely happens and cause is unknown."
    )
    return null
  }
}
