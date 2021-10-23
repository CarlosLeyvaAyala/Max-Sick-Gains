import { IntToHex } from "DM-Lib/Debug"
import { ForEachFormInCell, FormType } from "DM-Lib/Iteration"
import { AvoidRapidFire } from "DM-Lib/Misc"
import {
  Actor,
  Game,
  hooks,
  Keyword,
  on,
  printConsole,
  settings,
} from "skyrimPlatform"
import { LogVT } from "./debug"
import { fitStage } from "./database"
import * as S from "./sleep"

export function main() {
  printConsole("Max Sick Gains successfully initialized.")

  printConsole(fitStage(1))
  printConsole(fitStage(1).iName)
  printConsole(fitStage(1).muscleDefType)

  // on("update", () => {})

  const OnSleepStart = AvoidRapidFire(S.OnSleepStart)
  const OnSleepStop = AvoidRapidFire(S.OnSleepEnd)

  hooks.sendPapyrusEvent.add(
    {
      enter(_) {
        OnSleepStop()
      },
    },
    0x0,
    0x14,
    "OnSleepStop"
  )

  hooks.sendPapyrusEvent.add(
    {
      enter(_) {
        OnSleepStart()
      },
    },
    0,
    0x14,
    "OnSleepStart"
  )

  hooks.sendPapyrusEvent.add(
    {
      enter(_) {
        printConsole("attached")
      },
    },
    undefined,
    undefined,
    "OnAttachedToCell"
  )

  // on("equip", (e) => {
  //   const b = e.actor.getBaseObject()
  //   // if (b) printConsole(`EQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`);
  // });

  // on("objectLoaded", (e) => {
  //   if (e.isLoaded) {
  //     const a = Actor.from(e.object)
  //     if (!a) return
  //     const b = a.getLeveledActorBase()
  //     // const formId = LogVT("FormId", e.object?.getFormID(), IntToHex)
  //     printConsole(`Name: ${b?.getName()}`)
  //   }
  // })

  on("cellFullyLoaded", (e) => {
    return
    const p = Game.getPlayer()
    const k = Keyword.getKeyword("ActorTypeNPC")

    ForEachFormInCell(e.cell, FormType.NPC, (f) => {
      if (!f) return
      const a = Actor.from(f)
      if (
        !a ||
        a.isDisabled() ||
        !a.getRace()?.hasKeyword(k) ||
        a.getFormID() === p?.getFormID()
      )
        return
      // printConsole(a.getRace()?.getName())

      const b = a.getLeveledActorBase()
      printConsole(b?.getName())
    })
  })

  // on("unequip", (e) => {
  //   const b = e.actor.getBaseObject()
  //   // if (b) printConsole(`UNEQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`);
  // });
}
