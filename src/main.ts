import { fitStage, MuscleDefinitionType } from "./database"
import { ClearAppearance } from "./appearance/appearance"
import { AvoidRapidFire } from "DM-Lib/Misc"
import { Actor, Armor, Game, hooks, on, printConsole } from "skyrimPlatform"
import * as S from "./sleep"
import { SolveAppearance } from "./appearance/npc"

export function main() {
  // const c = 5
  // // printConsole(fitStage(1))
  // printConsole(fitStage(c).femBs)
  // BlendFemBs(fitStage(c), 10).forEach((v, k) => {
  //   printConsole(`${k}: ${v}`)
  // })
  // printConsole(fitStage(c).manBs)
  // BlendManBs(fitStage(c), 10).forEach((v, k) => {
  //   printConsole(`${k}: ${v}`)
  // })
  // printConsole(`Type: ${MuscleDefinitionType[fitStage(c).muscleDefType]}`)
  // printConsole(fitStage(c).iName)

  printConsole("Max Sick Gains successfully initialized.")

  // ;>========================================================
  // ;>===                 PLAYER EVENTS                  ===<;
  // ;>========================================================

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

  // ;>========================================================
  // ;>===             PLAYER AND NPC EVENTS              ===<;
  // ;>========================================================

  // Pizza hands fix
  on("equip", (e) => {
    const b = e.actor.getBaseObject()
    const armor = Armor.from(e.baseObj)
    if (!armor || armor.getSlotMask() !== 0x4) return

    if (b)
      printConsole(
        `EQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`
      )
  })

  // Pizza hands fix
  on("unequip", (e) => {
    const b = e.actor.getBaseObject()
    const armor = Armor.from(e.baseObj)
    if (!armor || armor.getSlotMask() !== 0x4) return

    if (b)
      printConsole(
        `UNEQUIP. actor: ${b.getName()}. object: ${e.baseObj.getName()}`
      )
  })

  // ;>========================================================
  // ;>===                   NPC EVENTS                   ===<;
  // ;>========================================================

  // Right now, NPC appearance is set by applying a Spell via SPID, since it's
  // the most reliable method to apply them settings as soon as they spawn.
  // That spell is empty and does nothing. All the work is done here.
  on("effectStart", (e) => {
    OnMaxickSpell(e.effect.getFormID(), Actor.from(e.target), SolveAppearance)
  })

  on("effectFinish", (e) => {
    OnMaxickSpell(e.effect.getFormID(), Actor.from(e.target), ClearAppearance)
  })
}

function OnMaxickSpell(
  spellId: number,
  target: Actor | null,
  DoSomething: (target: Actor | null) => void
) {
  const fx = Game.getFormFromFile(0x96c, "Max Sick Gains.esp")
  if (fx?.getFormID() !== spellId) return
  DoSomething(target)
}
