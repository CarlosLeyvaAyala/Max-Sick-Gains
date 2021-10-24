import { GetFormUniqueId } from "DM-Lib/Misc"
import { Actor, ActorBase } from "skyrimPlatform"
import { FitStage, fitStage, Sex } from "../database"
import { LogE, LogV } from "../debug"
import {
  ApplyBodyslide,
  BlendFemBs,
  BlendManBs,
  BodyslidePreset,
} from "./appearance"

export function SolveAppearance(a: Actor | null) {
  const d = GetActorData(a)
  if (!d) return
  LogV(`+++ ${d.uId}. ${d.name}, ${d.class}, ${Sex[d.sex]}`)
  const bs = GetBodyslide(d.base, d.sex, fitStage(5))
  ApplyBodyslide(d.actor, bs)
}

function GetActorData(a: Actor | null) {
  if (!a) return null
  const b = a.getLeveledActorBase()
  if (!b) {
    LogE("GetActorData: Couldn't find an ActorBase. Is that even possible?")
    return null
  }

  const uId = GetFormUniqueId(b, (e, i) => `${e}|0x${i.toString(16)}`)
  const n = b.getName() || ""
  const s = b.getSex()
  const c = b.getClass()?.getName() || ""

  // if (s !== Sex.female || s !== Sex.male) {
  //   LogE(`Sex for ${uId}|"${n}" is undefined. Can't continue processing.`)
  //   return null
  // }
  return { actor: a, base: b, sex: s, class: c, uId: uId, name: n }
}

function GetBodyslide(b: ActorBase, s: Sex, fs: FitStage): BodyslidePreset {
  const w = b.getWeight()
  return s === Sex.male ? BlendManBs(fs, w) : BlendFemBs(fs, w)
}
