import {
  AddSkinOverrideString,
  TextureIndex as Idx,
  Key,
} from "Racemenu/nioverride"
import { Actor, SlotMask } from "skyrimPlatform"
import { Sex } from "../../database"
import { LogV } from "../../debug"

export function applySkin(a: Actor, s: Sex, path: string | undefined) {
  LogV(`Applying skin ${path}`)

  const SkinAlias = (s: Sex) => {
    return {
      fem: s === Sex.female,
      t: Key.Texture,
      n: Idx.Diffuse,
      body: SlotMask.Body,
    }
  }

  // TODO: Clear if undefined
  if (!path) return

  const { fem, t, n, body } = SkinAlias(s)
  AddSkinOverrideString(a, fem, false, body, t, n, path, true)
}
