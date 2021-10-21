import { IntToHex } from "DM-Lib/Debug"
import { AvoidRapidFire, ListenPapyrusEvent } from "DM-Lib/Misc"
import { Actor, hooks, on, printConsole } from "skyrimPlatform"
import { LogVT } from "./debug"
import * as S from "./sleep"

export function main() {
  printConsole("Max Sick Gains successfully initialized.")

  // on("update", () => {})

  const OnSleepStart = AvoidRapidFire(S.OnSleepStart)
  const OnSleepStop = AvoidRapidFire(S.OnSleepEnd)

  // const SleepStart = ListenPapyrusEvent("OnSleepStart")
  // const SleepEnd = ListenPapyrusEvent("OnSleepStop")
  // const CellAttach = ListenPapyrusEvent("OnCellAttach")

  // hooks.sendPapyrusEvent.add({
  //   enter(c) {
  //     SleepStart(c, OnSleepStart)
  //     SleepEnd(c, OnSleepStart)
  //   },
  // })
  hooks.sendPapyrusEvent.add(
    {
      enter(_) {
        OnSleepStop()
      },
    },
    0,
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

  // on("equip", (e) => {
  //   const b = e.actor.getBaseObject()
  //   // if (b) printConsole(`EQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`);
  // });

  on("objectLoaded", (e) => {
    if (!e.isLoaded) {
      const a = Actor.from(e.object)?.getBaseObject()
      const formId = LogVT("FormId", e.object?.getFormID(), IntToHex)
      printConsole(`Name: ${a?.getName()}`)
    }
    // const l = Actor.from(Game.getFormEx(formId))?.getLeveledActorBase()
    // printConsole(
    //   `Leveled actor name ${l?.getName()} race: ${l
    //     ?.getRace()
    //     ?.getName()} class: ${l?.getClass()?.getName()}`
    // )
    // const base = Actor.from(e.object)?.getBaseObject()
    // printConsole(`Base actor name ${base?.getName()}`)
    // printConsole(`UNLOADED raw name ${e.object?.getName()}`)
    // const b = Actor.from(e.object)?.getLeveledActorBase()
    // if (b) {
    // const r = ActorBase.from(b)?.getRace()
    // const c = ActorBase.from(b)?.getClass()
    // printConsole(`(UN)LOADED object: ${b.getName()}. loaded: ${e.isLoaded} class: ${c?.getName()} race: ${r?.getName()}`);
    // }
  })

  on("cellFullyLoaded", (e) => {
    // printConsole(`CELL: ${e.cell.getName()}, attached: ${e.cell.isAttached()}`)
  })
  // on("unequip", (e) => {
  //   const b = e.actor.getBaseObject()
  //   // if (b) printConsole(`UNEQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`);
  // });
}
