import { Alt } from "DM-Lib/Combinators"
import { IntToHex } from "DM-Lib/Debug"
import { LinCurve } from "DM-Lib/Math"
import { GetFormEspAndId, RandomElement } from "DM-Lib/Misc"
import { GetActorRaceEditorID as GetRaceEDID } from "PapyrusUtil/MiscUtil"
import { Actor, ActorBase } from "skyrimPlatform"
import {
  ClassArchetype,
  classArchetype,
  ClassMatch,
  fitStage,
  MuscleDefinition,
  MuscleDefinitionType,
  RacialGroup,
  Sex,
} from "../database"
import { LogE, LogI, LogIT, LogV, LogVT } from "../debug"
import {
  ApplyBodyslide,
  BodyslidePreset,
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
  fitStageId: number
  muscleDef: MuscleDefinition
  weight: number
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
}

/** Changes an `Actor` appearance according to what they should look like.
 *
 * @param a The `Actor` to change their appearance.
 */
export function ChangeAppearance(a: Actor | null) {
  const d = LogIT("+++", GetActorData(a), NPCDataToStr)
  if (!d) return
  const r = SolveAppearance(d)
  if (r.bodyslide) ApplyBodyslide(d.actor, r.bodyslide)
}

/** Removes body morphs and texture overrides to avoid save game bloating.
 * @param a `Actor` to clear their appearance.
 */
export function ClearAppearance(a: Actor | null) {
  LogV(`--- ${NPCDataToStr(GetActorData(a))}`)
  ClearActorAppearance(a)
}

/** Gets appearance data for an `Actor`.
 * @param a `Actor` to get their appearance.
 * @returns Fitness stage, muscle definition and adjusted weight according to their Class Archetype.
 */
function SolveAppearance(d: NPCData): Appearance {
  // If it's not a Known NPC, it's a generic one.
  const raw = Alt(SolveKnownNPC, SolveGenericNPC)(d)
  const bs = GetBodyslide(
    fitStage(raw.fitStageId),
    d.sex,
    LogIT("Applied weight", raw.weight)
  )
  return { bodyslide: bs }
}

function SolveKnownNPC(d: NPCData): RawAppearance | null {
  return null
}

//#region Generic NPC solving

/** Gets the {@link RawAppearance} of a Generic NPC.
 *
 * @param d {@link NPCData}
 */
function SolveGenericNPC(d: NPCData): RawAppearance {
  // Get RawAppearance from class archetype
  const arch = Alt(SolveArchetype, DefaultArchetype)(d)
  LogI(`Selected archetype: ${arch.iName}`)

  return {
    fitStageId: arch.fitStage,
    weight: LinCurve(
      { x: 0, y: arch.bsLo },
      { x: 100, y: arch.bsHi }
    )(d.weight),
    muscleDef: {
      level: LinCurve(
        { x: 0, y: arch.muscleDefLo },
        { x: 100, y: arch.muscleDefHi }
      )(d.weight),
      // TODO: Get real values
      process: false,
      type: MuscleDefinitionType.plain,
      racialGroup: RacialGroup.Hum,
    },
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
