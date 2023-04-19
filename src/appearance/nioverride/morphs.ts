import {
  AddNodeOverrideString,
  AddSkinOverrideString,
  ClearBodyMorphNames,
  ClearMorphs,
  GetSkinOverrideString,
  TextureIndex as Idx,
  Key,
  Key as NiOKey,
  RemoveAllReferenceOverrides,
  RemoveAllReferenceSkinOverrides,
  RemoveSkinOverride,
  SetBodyMorph,
  UpdateModelWeight,
} from "Racemenu/nioverride"
import { Actor, NetImmerse } from "skyrimPlatform"
import { LogE } from "../../debug"
import { BodyShape, BodyslidePreset } from "../bodyslide"

function applyHeadSize(a: Actor, size: number) {
  const headNode = "NPC Head [Head]"
  if (NetImmerse.hasNode(a, headNode, false)) {
    NetImmerse.setNodeScale(a, headNode, size, false)
    updateNiNode(a)
  }
}

function updateNiNode(a: Actor) {
  if (a.isOnMount()) {
    LogE("ERROR: Can't update a character while mounting.")
    return
  }
  a.queueNiNodeUpdate()
}

function applyBodyslide(a: Actor, bs: BodyslidePreset | undefined) {
  const maxick = "Maxick"
  // ClearBodyMorphNames(a, maxick)

  if (!bs) return
  ClearMorphs(a) // TODO: Check if needed

  bs.forEach((v, sl) => {
    SetBodyMorph(a, sl, maxick, v)
  })

  UpdateModelWeight(a)
}

export type ShapeSetter = (a: Actor, shape?: BodyShape) => void

export const applyBodyShape: ShapeSetter = (a, shape) => {
  applyHeadSize(a, shape?.headSize ?? 1.0)
  applyBodyslide(a, shape?.bodySlide ?? undefined)
}

export const dontApplyBodyShape: ShapeSetter = (_, __) => {}
