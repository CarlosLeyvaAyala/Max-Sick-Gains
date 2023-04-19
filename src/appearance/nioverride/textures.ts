import { Actor } from "skyrimPlatform"
import { applyMuscleDef } from "./_muscle"
import { applySkin } from "./_skin"
import { Sex } from "../../database"
import { TexturePaths } from "../common"

export function applyTextures(
  a: Actor,
  s: Sex,
  textures: TexturePaths | undefined
) {
  applyMuscleDef(a, s, textures?.muscle ?? undefined)
  applySkin(a, s, textures?.skin ?? undefined)
}
