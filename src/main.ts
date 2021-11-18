import { IntToHex } from "DM-Lib/Debug"
import * as Hotkeys from "DM-Lib/Hotkeys"
import * as JDB from "JContainers/JDB"
import { AvoidRapidFire } from "DM-Lib/Misc"
import { FormLib } from "Dmlib"
import {
  Actor,
  Armor,
  DxScanCode,
  EquipEvent,
  Game,
  hooks,
  on,
  printConsole,
  SlotMask,
  Utility,
} from "skyrimPlatform"
import { isJSDocPublicTag } from "../node_modules/typescript/lib/typescript"
import { EquipPizzaHandsFix, FixGenitalTextures } from "./appearance/appearance"
import {
  ChangeAppearance as ChangeNpcAppearance,
  ClearAppearance as ClearNpcAppearance,
} from "./appearance/npc"
import { Player, TestMode } from "./appearance/player"
import { LogE, LogIT, LogV, LogVT } from "./debug"
import * as S from "./sleep"

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

  // hooks.sendPapyrusEvent.add(
  //   {
  //     enter(_) {
  //       Player.Calc.Update()
  //     },
  //   },
  //   undefined,
  //   undefined,
  //   "OnMaxickUpdate"
  // )

  // Event comming from Papyrus
  hooks.sendPapyrusEvent.add(
    {
      enter(_) {
        Player.Calc.Train.OnTrain(JDB.solveStr(".maxickEv.skillUp"))
      },
    },
    undefined,
    undefined,
    "OnMaxickSkill"
  )

  // ;>========================================================
  // ;>===             PLAYER AND NPC EVENTS              ===<;
  // ;>========================================================

  on("equip", (e) => {
    OnUnEquip(e, "EQUIP")
  })

  on("unequip", (e) => {
    OnUnEquip(e, "UNEQUIP", (a, slot) => {
      if (slot !== SlotMask.Hands) return
      EquipPizzaHandsFix(a)
    })
  })

  /** Updating cycle that calculates decay and inactivity. */
  const Update = async () => {
    while (true) {
      Player.Calc.Update()
      await Utility.wait(3)
    }
  }

  on("loadGame", () => {
    LogV("||| Game loaded |||")
    Player.Init()
    Player.Appearance.Change()
    // Fixme: Add this event when starting the game
    Update()
  })

  on("reset", (e) => {
    LogE(`$$$$$$$$$$$$$$$$$$$$$$$$$$ ${e.object.getName()}`)
    LogV("||||||||||||||||||||| Game reset |||")
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

  const T = Hotkeys.ListenTo(DxScanCode.PgDown) // pgdown
  const OnDebugNpc = Hotkeys.ListenTo(DxScanCode.End) // end key
  const OnPrint = Hotkeys.ListenTo(DxScanCode.MiddleMouseButton)

  on("update", () => {
    TestMode.Next(TestMode.GoNext)
    TestMode.Prev(TestMode.GoPrev)
    TestMode.Add10(TestMode.GoAdd10)
    TestMode.Sub10(TestMode.GoSub10)
    TestMode.SlideShow(TestMode.GoSlideShow)

    OnPrint(() => {
      Player.Calc.Train.OnTrain("OneHanded")
      // f()
      // MiscUtil.SetFreeCameraSpeed(80)
      // MiscUtil.SetFreeCameraState(true, 1)
      // Debug.toggleMenus()
      // MiscUtil.SetMenus(true)
      // tm.execute("")
    })

    OnDebugNpc(() => {
      let r = LogIT(
        "Getting reference at crosshair",
        Game.getCurrentCrosshairRef()
      )
      if (!r)
        r = LogIT(
          "No reference found at crosshair. Trying console one",
          Game.getCurrentConsoleRef()
        )
      if (!r) return
      if (r.getFormID() === Game.getPlayer()?.getFormID())
        Player.Appearance.Change()
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
 * @remarks
 * Can be used to solve the Pizza Hands Syndrome as well.
 *
 * @param e Event variable.
 * @param evMsg Message to log.
 * @param DoSomething As extra function to execute.
 */
function OnUnEquip(
  e: EquipEvent,
  evMsg: string,
  DoSomething?: (actor: Actor, slot: number) => void
) {
  // Basic validity checks
  const a = Actor.from(e.actor)
  const b = a?.getLeveledActorBase()
  const armor = Armor.from(e.baseObj)
  if (!a || !b || !armor) return

  // Only cares for cuirasses and gauntlets
  const sl = armor.getSlotMask()
  if (sl !== SlotMask.Body && sl !== SlotMask.Hands) return

  LogV(
    `${evMsg}. Actor: ${b.getName()}. Id: 0x${IntToHex(
      a.getFormID()
    )}. Object: ${e.baseObj.getName()}. Slot: ${sl}`
  )

  // Wait before fixing things because Skyrim Platform is TOO fast <3.
  const actor = FormLib.PreserveActor(a)
  const f = async () => {
    await Utility.wait(0.01)
    const a = actor()

    if (!a) return
    if (sl === SlotMask.Body) FixGenitalTextures(a)
    if (DoSomething) DoSomething(a, sl)
  }
  f()
}
