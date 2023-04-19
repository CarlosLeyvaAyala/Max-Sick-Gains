import { Actor } from "skyrimPlatform"
import { applyMuscleDef } from "./_muscle"
import { applySkin } from "./_skin"
import { Sex } from "../../database"
import { TexturePaths } from "../common"

export type TextureSetter = (
  a: Actor,
  s: Sex,
  textures: TexturePaths | undefined
) => void

export const applyTextures: TextureSetter = (a, s, textures) => {
  applyMuscleDef(a, s, textures?.muscle ?? undefined)
  applySkin(a, s, textures?.skin ?? undefined)
}

export const dontApplyTextures: TextureSetter = (_, __, ___) => {}
