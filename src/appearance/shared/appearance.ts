import { BodyShape } from "../bodyslide"
import { TexturePaths } from "../common"

export interface ApplyAppearanceData {
  bodyShape?: BodyShape
  textures?: TexturePaths
  saveToCache: () => void
}
