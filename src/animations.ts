import { hooks, once } from "skyrimPlatform"
import { playerId } from "./constants"

export function HookAnim(animName: string, f: () => void) {
  hooks.sendAnimationEvent.add(
    {
      enter(_) {},
      leave(c) {
        if (c.animationSucceeded) once("update", () => f())
      },
    },
    playerId,
    playerId,
    animName
  )
}
