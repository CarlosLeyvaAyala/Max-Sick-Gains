import { AvoidRapidFire } from "DM-Lib/Misc"
import * as Hotkeys from "DM-Lib/Hotkeys"
import {
  Actor,
  Armor,
  EquipEvent,
  Game,
  hooks,
  on,
  printConsole,
  Utility,
  writeLogs,
} from "skyrimPlatform"
import {
  ChangeAppearance as ChangeNpcAppearance,
  ClearAppearance as ClearNpcAppearance,
} from "./appearance/npc"
import * as S from "./sleep"
import { LogE, LogV } from "./debug"
import { EquipPizzaHandsFix, FixGenitalTextures } from "./appearance/appearance"

export function main() {
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

  on("equip", (e) => {
    OnUnEquip(e, "EQUIP")
  })
  // const t = new Date().toLocaleString()
  // writeLogs("maxick", `${t}: ${b.getName()} equipped ${e.baseObj.getName()}`)

  on("unequip", (e) => {
    OnUnEquip(e, "UNEQUIP", (id, slot) => {
      if (slot !== 0x8) return

      const f = async () => {
        await Utility.wait(0.1)
        const a = Actor.from(Game.getFormEx(id))
        if (!a) return
        EquipPizzaHandsFix(a)
      }
      f()
    })
  })

  // ;>========================================================
  // ;>===                   NPC EVENTS                   ===<;
  // ;>========================================================

  // Right now, NPC appearance is set by applying a Spell via SPID, since it's
  // the most reliable method to apply them settings as soon as they spawn.
  // That spell is empty and does nothing. All the work is done here.
  on("effectStart", (e) => {
    OnMaxickSpell(
      e.effect.getFormID(),
      Actor.from(e.target),
      ChangeNpcAppearance
    )
  })

  on("effectFinish", (e) => {
    OnMaxickSpell(
      e.effect.getFormID(),
      Actor.from(e.target),
      ClearNpcAppearance
    )
  })

  // const OnDebugNpc = Hotkeys.ListenTo(199) // home key
  const OnDebugNpc = Hotkeys.ListenTo(207) // end key

  on("update", () => {
    OnDebugNpc(() => {
      const r = Game.getCurrentConsoleRef()
      if (!r) return
      if (r.getFormID() === Game.getPlayer()?.getFormID())
        LogE("Yeah... nice try, Einstein. GO EARN YOUR GAINS, YOU LOAFER!")
      else ChangeNpcAppearance(Actor.from(r))
    })
  })
}

/** Do something when the Maxick spell effect starts/end.
 *
 * @remarks
 * That spell is appiled via SPID and it's blank. All work is done here in Typescript.
 *
 * @param spellId Id of the Magic Effect that was applied/finished.
 * @param target Target `Actor` of the spell.
 * @param DoSomething What to do if the spell was the Maxick one.
 * @returns void
 */
function OnMaxickSpell(
  spellId: number,
  target: Actor | null,
  DoSomething: (target: Actor | null) => void
) {
  const fx = Game.getFormFromFile(0x96c, "Max Sick Gains.esp") // Maxick Magic Effect
  if (fx?.getFormID() !== spellId) return
  DoSomething(target)
}

/** Solves wrong genital textures due to texture overrides.
 *
 * @param e Event variable.
 * @param evMsg Message to log.
 * @param DoSomething As extra function to execute.
 */
function OnUnEquip(
  e: EquipEvent,
  evMsg: string,
  DoSomething?: (actor: number, slot: number) => void
) {
  const a = Actor.from(e.actor)
  const b = a?.getLeveledActorBase()
  const armor = Armor.from(e.baseObj)
  if (!a || !b || !armor) return

  const sl = armor.getSlotMask()
  if (sl !== 0x4 && sl !== 0x8) return

  LogV(
    `${evMsg}. Actor: ${b.getName()}. Object: ${e.baseObj.getName()}. Slot: ${sl}`
  )
  if (sl === 0x4) FixGenitalTextures(a)

  if (DoSomething) DoSomething(a.getFormID(), sl)
}
