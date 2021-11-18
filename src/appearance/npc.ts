import { Alt } from "DM-Lib/Combinators"
import { IntToHex, LogR } from "DM-Lib/Debug"
import { GetFormEspAndId } from "DM-Lib/Misc"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
import { Actor, ActorBase } from "skyrimPlatform"
import {
  ClassArchetype,
  classArchetype,
  ClassMatch,
  fitStage,
  KnownNpcData,
  knownNPCs,
  MuscleDefinition,
  RacialMatch,
  Sex,
} from "../database"
import { LogE, LogI, LogIT, LogV, LogVT } from "../debug"
import {
  ApplyBodyslide,
  ApplyMuscleDef,
  BodyslidePreset,
  ChangeHeadSize,
  ClearAppearance as ClearActorAppearance,
  GetBodyslide,
  GetHeadSize,
  GetMuscleDefTex,
  InterpolateMusDef,
  InterpolateW,
  IsMuscleDefBanned,
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

interface BodyslideData {
  preset: BodyslidePreset
}

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

enum NpcType {
  known,
  generic,
}

interface NpcOptions {
  applyMorphs: boolean
  applyMuscleDef: boolean
}

interface AllNpcOptions {
  knownFem: NpcOptions
  knownMan: NpcOptions
  genericFem: NpcOptions
  genericMan: NpcOptions
}

// TODO: Delete
const mockOptions: AllNpcOptions = {
  knownFem: { applyMorphs: true, applyMuscleDef: true },
  knownMan: { applyMorphs: true, applyMuscleDef: true },
  genericFem: { applyMorphs: true, applyMuscleDef: true },
  genericMan: { applyMorphs: true, applyMuscleDef: true },
}

/** Changes an `Actor` appearance according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeAppearance(a: Actor | null) {
  const d = LogIT("+++", GetActorData(a), NPCDataToStr)
  if (!d) return

  const r = SolveAppearance(d, mockOptions)
  if (r.bodyslide) ApplyBodyslide(d.actor, r.bodyslide)
  if (r.headSize) ChangeHeadSize(d.actor, r.headSize)
  ApplyMuscleDef(d.actor, d.sex, r.path)
}

/** Removes body morphs and texture overrides to avoid save game bloating.
 * @param a `Actor` to clear their appearance.
 */
export function ClearAppearance(a: Actor | null) {
  LogV(`--- ${NPCDataToStr(GetActorData(a))}`)
  ClearActorAppearance(a)
}

/** Invalid raw appearance */
const iRawApp = { fitStageId: -1 }

const InvalidRace = (d: NPCData) => {
  LogE(
    `NPC 0x${d.actor
      .getFormID()
      .toString(16)} does not belong to any known racial group.`
  )
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
function SolveAppearance(d: NPCData, o: AllNpcOptions): Appearance {
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

function SolveKnownNPC(d: NPCData, o: AllNpcOptions): RawAppearance | null {
  //@ts-ignore
  const esp = knownNPCs[d.esp.toLowerCase()]
  if (!esp) return null
  const kn = esp[d.fixedFormId] as KnownNpcData
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
function SolveGenericNPC(d: NPCData, o: AllNpcOptions): RawAppearance {
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
 * @returns A {@link ClassArchetype}. `null` if none was found.
 */
function SolveArchetype(d: NPCData): ClassArchetype | null {
  const archs = LogVT(
    "All possible unfiltered archetypes",
    ClassMatch(d.name, d.class)
  )
  let exclusive: ClassArchetype[] = []
  let nonExclusive: ClassArchetype[] = []
  archs.forEach((v, _, __) => {
    FilterViableArchetypes(
      classArchetype(v),
      d.race.toLowerCase(),
      exclusive,
      nonExclusive
    )
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
 * @param ar Archetype to test.
 * @param race Lowercase race EDID of the NPC.
 * @param exclusive Array containing all archetypes where the NPC has race exclusiveness.
 * @param nonExclusive Array with all non exclusive archetype the NPC matched.
 */
function FilterViableArchetypes(
  ar: ClassArchetype,
  race: string,
  exclusive: ClassArchetype[],
  nonExclusive: ClassArchetype[]
) {
  // TODO: Discard archetypes with out of bounds weights
  if (ar.raceExclusive.length > 0) {
    if (ar.raceExclusive.some((r, _) => race.indexOf(r) >= 0))
      exclusive.push(ar)
  } else nonExclusive.push(ar)
}

function DefaultArchetype(_: NPCData): ClassArchetype {
  return {
    iName: "Default",
    fitStage: 1,
    bsLo: 0,
    bsHi: 100,
    muscleDefLo: 1,
    muscleDefHi: 6,
    raceExclusive: [],
  }
}
//#endregion

/** Returns "MCM" options for an NPC, according to their sex and type.
 *
 * @param d
 * @param o
 * @param t
 */
function GetNpcOptions(s: Sex, t: NpcType, o: AllNpcOptions): NpcOptions {
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

  return `BaseID: ${IntToHex(d.base.getFormID())} RefId: ${IntToHex(
    d.actor.getFormID()
  )} FixId: ${d.fixedFormId} ${d.esp}|0x${d.fixedFormId.toString(16)}. ${
    d.class
  }, ${d.race}, ${Sex[d.sex]}, weight: ${d.weight}, ${d.name}`
}

/** Gets all `Actor` needed data to process them.
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
