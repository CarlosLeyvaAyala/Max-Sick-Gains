import * as Maps from "DmLib/typescript/Map"
import { LinCurve } from "DmLib/Math"
import { LogI, LogN, LogNT, LogV } from "../../../../debug"
import {
  ActorAppearanceSettings,
  FitJourney,
  FitStage,
  JourneyStage,
  db,
} from "../../../../types/exported"
import {
  BodyShape,
  BodyslidePreset,
  blendBs,
  blendMorph,
} from "../../../bodyslide"
import { weightInterpolation } from "../../../common"

const CantChangeMDef = "Can't change muscle definition."
const MDefMcmBan = () => {
  LogI(`Muscle definition changing is banned. ${CantChangeMDef}`)
}
const MDefRaceBan = () => {
  LogI(`Race is banned from changing muscle defininion. ${CantChangeMDef}`)
}
// const NoBase = () => {
//   LogE("No base object for player (how is that even possible?)")
// }

/** Data needed to change the player appearance. */
// interface PlayerData {
//   race: string
//   sex: Sex
//   gains: number
//   racialGroup: RacialGroup
//   /** Current player stage id. */
//   playerStageId: number
//   /** Current player stage object. */
//   playerStage: PlayerStage
//   /** Fitness Stage asociated to the current Player Stage. */
//   fitnessStage: FitStage
// }

/** Data needed to calculate a blended Bodyslide. */
interface BlendData {
  /** Fitness Stage object. */
  fitStage: FitStage
  /** Player stage object */
  // playerStage: PlayerStage
  journeyStage: JourneyStage
  /** How much this Fitness Stage contributes to blending. */
  blend: number
  /** On which `gains` this Fitness Stage appearance will be calculated. */
  gains: number
  /** Weight at which data will be calculated. It's based Journey Stage weight limits. */
  weight: number
}

/** Data needed to calculate the final player Bodyslide. */
interface BlendPair {
  /** Current Journey Stage data. */
  blend1: BlendData
  /** Blending Journey Stage data. */
  blend2: BlendData
}

/** Gets the data needed to change the player appearance. */
// function GetData(p: Actor): PlayerData | undefined {
//   const b = ActorBase.from(p.getBaseObject())
//   if (!b) return LogR(NoBase(), undefined)

//   const race = LogIT("Race", GetRaceEDID(p))

//   const sex = b.getSex()
//   LogI(`Sex: ${Sex[sex]}`)

//   const racialGroup = O(RacialMatch, K(RacialGroup.Ban))(race)
//   LogI(`Racial group: ${RacialGroup[racialGroup]}`)

//   const s = CurrentStage()
//   const fs = fitStage(s.fitStage)
//   LogV(`Player Stage [${pStage}]: "${fs.iName}" [${s.fitStage}]`)

//   return {
//     race: race,
//     sex: sex,
//     racialGroup: racialGroup,
//     playerStageId: pStage,
//     playerStage: s,
//     fitnessStage: fs,
//     gains: gains,
//   }
// }

/** Changes the player appearance. */
// export function Change() {
//   LogV("Changing appearance.")
//   ChangeAppearance(true, true)
// }

// export function ChangeMuscleDef() {
//   LogV("Changing muscle definition.")
//   ChangeAppearance(false, true)
// }

///////////////////////////////////////////////////////////////
// function ChangeAppearance(applyBs: boolean, applyMuscleDef: boolean) {
//   const p = Game.getPlayer() as Actor
//   const d = GetData(p)
//   if (!d) return
//   const shape = GetBodyShape(d)
//   if (shape && applyBs) {
//     LogBs(shape.bodySlide, "Final preset", LogV)
//     ApplyBodyslide(p, shape.bodySlide)
//     ChangeHeadSize(p, shape.headSize)
//   }
//   if (applyMuscleDef) {
//     const tex = GetMuscleDef(d)
//     ApplyMuscleDef(p, d.sex, tex)
//   }
// }

export function calculateAppearance(
  journey: FitJourney,
  stage: number,
  gains: number,
  isFem: boolean,
  canApply: ActorAppearanceSettings
) {
  const shape = canApply.applyMorphs
    ? getBodyShape(journey, stage, gains, isFem)
    : {
        bodySlide: undefined,
        headSize: undefined,
      }
  const texs = canApply.applyMuscleDef ? undefined : undefined
  return { bodyShape: shape }
}

function getBodyShape(
  j: FitJourney,
  stage: number,
  gains: number,
  isFem: boolean
): BodyShape {
  let b = getBlends(j, stage, gains)

  return {
    bodySlide: getBodySlide(b, isFem),
    headSize: getHeadS(b, isFem),
  }
}

/** Get head size */
function getHeadS(b: BlendPair, isFem: boolean) {
  const B = (bl: BlendData) => {
    if (bl.blend === 0) return 0
    const app = isFem ? bl.fitStage.man : bl.fitStage.fem
    const hs = weightInterpolation(bl.weight, app.headLo, app.headHi)
    return hs * bl.blend
  }

  const s1 = LogNT("Current stage head size", B(b.blend1))
  const s2 = LogNT("Blend stage head size", B(b.blend2))
  return LogNT("Head size", s1 + s2)
}

/** Returns a fully blended Bodyslide preset. Ready to be applied on the player.
 *
 * @param d Player data.
 * @returns A fully blended {@link BodyslidePreset} or `undefined` (that last thing
 * should actually never happen).
 */
function getBodySlide(b: BlendPair, isFem: boolean) {
  const { blend1: b1, blend2: b2 } = b
  const L = (b: BlendData) =>
    `fitStage (${b.fitStage.iName}), blend (${b.blend}), simulated weight: (${b.weight})`

  LogN("Bodyslide blending")

  const sl1 = getSliders(
    LogNT("Current Stage", b1, L),
    isFem
  ) as BodyslidePreset // Sl1 always exist
  const sl2 = getSliders(LogNT("Blend Stage", b2, L), isFem)

  // const r = Maps.join(sl1, sl2, (v1, v2) => v1 + v2)
  // Maps.toArray(r).forEach(([sl, v]) => LogN(`${sl}: ${v}`))
  // return r
  return Maps.join(sl1, sl2, (v1, v2) => v1 + v2)
}

/** Calculates the Bodyslide associated to some blend.
 *
 * @param d Player data.
 * @param b Blending data.
 * @returns Fully formed Bodyslide preset.
 */
function getSliders(b: BlendData, isFem: boolean) {
  if (b.blend === 0) return null
  const app = isFem ? b.fitStage.man : b.fitStage.fem
  return blendBs(app, b.weight, blendMorph(b.blend))
}

/** Returns which data will be used for blending appearance between two _Player Stages_.
 *
 * @param d Player data.
 * @returns Current and Blending stage data.
 */
function getBlends(j: FitJourney, stage: number, gains: number): BlendPair {
  const currentStage = j.stages[stage]
  const lastStage = j.stages.length - 1
  const lBlendLim = currentStage.blend
  const uBlendLim = 100 - lBlendLim
  let b1 = 0
  let g2 = 0
  let blendStage = 0

  if (lBlendLim >= gains && stage > 0) {
    LogV("Current stage was blended with previous")
    blendStage = stage - 1
    g2 = 100
    b1 = LinCurve({ x: 0, y: 0.5 }, { x: lBlendLim, y: 1 })(gains)
  } else if (uBlendLim <= gains && stage < lastStage) {
    LogV("Current stage was blended with next")
    blendStage = stage + 1
    g2 = 0
    b1 = LinCurve({ x: uBlendLim, y: 1 }, { x: 100, y: 0.5 })(gains)
  } else {
    LogV("No blending needed")
    blendStage = stage
    b1 = 1
  }

  const getFS = (fsId: number) => db.fitStages[fsId.toString()]
  const getW = (g: number, jStage: JourneyStage) =>
    weightInterpolation(g, jStage.bsLo, jStage.bsHi)

  const js1 = currentStage
  const js2 = j.stages[blendStage]
  const fs1 = getFS(js1.fitStage)
  const fs2 = getFS(js2.fitStage)
  return {
    blend1: {
      fitStage: fs1,
      journeyStage: js1,
      gains: gains,
      blend: b1,
      weight: getW(gains, js1),
    },
    blend2: {
      fitStage: fs2,
      journeyStage: js2,
      gains: g2,
      blend: 1 - b1,
      weight: getW(g2, js2),
    },
  }
}

////////////////////////////////////////////////////////////////////
/** Returns the muscle definition texture the player should use. */
// function GetMuscleDef(d: PlayerData) {
//   if (!mcm.actors.player.applyMuscleDef) return LogR(MDefMcmBan(), undefined)
//   if (IsMuscleDefBanned(d.race)) return LogR(MDefRaceBan(), undefined)

//   const mdt = d.fitnessStage.muscleDefType
//   const md = InterpolateMusDef(
//     d.playerStage.muscleDefLo,
//     d.playerStage.muscleDefHi,
//     gains
//   )
//   return GetMuscleDefTex(d.sex, d.racialGroup, mdt, md, LogIT)
// }
