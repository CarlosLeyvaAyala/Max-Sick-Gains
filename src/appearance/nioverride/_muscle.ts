import { waitActor } from "DmLib/Actor"
import { IntToHex } from "DmLib/Log"
import {
  AddNodeOverrideString,
  AddSkinOverrideString,
  GetSkinOverrideString,
  TextureIndex as Idx,
  Key,
  Key as NiOKey,
  RemoveSkinOverride,
} from "Racemenu/nioverride"
import {
  Actor,
  ActorBase,
  Armor,
  Game,
  NetImmerse,
  SlotMask,
} from "skyrimPlatform"
import { Sex } from "../../database"
import { LogI, LogV, LogVT } from "../../debug"

/** Shortcut name to change muscle definition */
const MDefAlias = (s: Sex) => {
  return {
    fem: s === Sex.female,
    t: Key.Texture,
    n: Idx.Normal,
    body: SlotMask.Body,
  }
}

export function applyMuscleDef(a: Actor, s: Sex, path: string | undefined) {
  LogI(`Applying muscle definition ${path}`)

  if (!path) {
    removeMuscleDef(a, s)
    return
  }

  const { fem, t, n, body } = MDefAlias(s)
  AddSkinOverrideString(a, fem, false, body, t, n, path, true)
  AddSkinOverrideString(a, fem, true, body, t, n, path, true)

  waitActor(a, 0.05, (aa) => {
    LogV("Fixing hands and genitals")
    equipPizzaHandsFix(aa)
    fixGenitalTextures(aa)
  })
}

function removeMuscleDef(a: Actor, s: Sex) {
  LogV("Removing muscle definition and pizza hands fix")
  const pf = pizzaFix()
  a.unequipItem(pf, true, true)
  a.removeItem(pf, a.getItemCount(pf), true, null)

  const { fem, t, n, body } = MDefAlias(s)
  RemoveSkinOverride(a, fem, false, body, t, n)
  RemoveSkinOverride(a, fem, true, body, t, n)
}

const pizzaFix = () => Game.getFormFromFile(0x9dc, "Max Sick Gains.esp")

export function equipPizzaHandsFix(a: Actor) {
  const skO = LogVT(
    "Skin override",
    GetSkinOverrideString(
      a,
      LogVT("Is fem", isFem(a)),
      false,
      SlotMask.Body,
      NiOKey.Texture,
      Idx.Normal
    ).trim()
  )
  const g = Armor.from(a.getWornForm(SlotMask.Hands))
  LogV(`Current gauntlets: ${g?.getName()} (${IntToHex(g?.getFormID() || 0)})`)
  const exit = LogVT("Don't fix pizza hands?", g || skO === "")
  if (exit) return

  LogV("No gauntlets equipped. Solving the Pizza Hands Syndrome.")
  a.equipItem(pizzaFix(), false, true)
}

export function isFem(a: Actor) {
  const b = ActorBase.from(a.getLeveledActorBase())
  if (!b) return false
  return b.getSex() === Sex.female
}

/** Fixes messed up anus and vagina textures.
 * @remarks
 * Setting normal maps messes with vagina and anus textures because they are
 * technically part of the skin.
 * This function sets back the textures that should be there.
 *
 * @param a Actor to fix textures for.
 */
export function fixGenitalTextures(a: Actor) {
  fix3BAGenitals(a)
}

function fix3BAGenitals(a: Actor) {
  const b = "data\\textures\\actors\\character\\female\\femalebody_etc_v2_1"
  const d = b + ".dds"
  const n = b + "_msn.dds"
  const sk = b + "_sk.dds"
  const s = b + "_s.dds"
  nodeOverride(a, true, "3BA_Vagina", d, n, sk, s)
  nodeOverride(a, true, "3BA_Anus", d, n, sk, s)
  nodeOverride(a, true, "3BBB_Vagina", d, n, sk, s)
  nodeOverride(a, true, "3BBB_Anus", d, n, sk, s)
}

function nodeOverride(
  a: Actor,
  isFem: boolean,
  node: string,
  d: string,
  n: string,
  sk: string,
  s: string
) {
  if (!NetImmerse.hasNode(a, node, false)) return

  LogV(`Fixing genital node textures: ${node}`)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Diffuse, d, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Normal, n, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Skin, sk, false)
  AddNodeOverrideString(a, isFem, node, Key.Texture, Idx.Specular, s, false)
}
