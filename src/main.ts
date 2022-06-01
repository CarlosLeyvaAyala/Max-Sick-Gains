import { ActorValueToStr, playerId } from "constants"
import { DebugLib, FormLib, Hotkeys, MathLib, Misc } from "Dmlib"
import * as JDB from "JContainers/JDB"
import {
  Actor,
  Armor,
  DxScanCode,
  EquipEvent,
  Game,
  on,
  once,
  printConsole,
  SlotMask,
  Spell,
  Utility,
} from "skyrimPlatform"
import { EquipPizzaHandsFix, FixGenitalTextures } from "./appearance/appearance"
import {
  ChangeAppearance as ChangeNpcAppearance,
  ClearAppearance as ClearNpcAppearance,
} from "./appearance/npc"
import { Player, Sleep, TestMode } from "./appearance/player"
import { LogI, LogIT, LogV } from "./debug"

const initK = ".DmPlugins.Maxick.init"
const MarkInitialized = () => JDB.solveBoolSetter(initK, true, true)
const WasInitialized = () => JDB.solveBool(initK, false)

export function main() {
  // ;>========================================================
  // ;>===                 PLAYER EVENTS                  ===<;
  // ;>========================================================

  //#region Player events
  on("sleepStop", (_) => {
    Sleep.OnEnd()
  })

  on("sleepStart", (_) => {
    Sleep.OnStart()
  })

  on("skillIncrease", (e) => {
    Player.Calc.Training.OnTrain(ActorValueToStr(e.actorValue))
  })

  let allowInit = false

  on("loadGame", () => {
    LogV("||| Game loaded |||")
    Initialze()
    allowInit = true
  })

  once("update", () => {
    if (allowInit || !WasInitialized()) Initialze()
  })

  on("switchRaceComplete", (e) => {
    if (e.subject.getFormID() === playerId) Player.Appearance.Change()
  })

  on("modEvent", (e) => {
    const Exe = (f: () => void) => {
      LogI(`Mod event recieved. ${e.eventName}.`)
      f()
    }

    if (e.eventName === "Maxick_Train")
      Exe(() => Player.Calc.Training.OnTrain(e.strArg))
  })

  const Initialze = () => {
    Player.Init()
    Player.Appearance.Change()
    MarkInitialized()
  }
  //#endregion

  // ;>========================================================
  // ;>===             PLAYER AND NPC EVENTS              ===<;
  // ;>========================================================

  //#region Player and NPC events
  on("equip", (e) => {
    Actor.from(e.actor)?.addSpell(
      Spell.from(Game.getFormFromFile(0x96d, "Max Sick Gains.esp")),
      false
    )

    OnUnEquip(e, "EQUIP")
  })

  on("unequip", (e) => {
    OnUnEquip(e, "UNEQUIP", (a, slot) => {
      if (slot !== SlotMask.Hands) return
      EquipPizzaHandsFix(a)
    })
  })
  //#endregion

  // ;>========================================================
  // ;>===                   NPC EVENTS                   ===<;
  // ;>========================================================

  //#region NPC events

  // Right now, NPC appearance is set by applying a Spell via SPID, since it's
  // the most reliable method to apply them settings as soon as they spawn.
  // That spell is empty and does nothing. All the work is done here.
  on("effectStart", (e) => {
    if (!e.effect) return
    OnMaxickSpell(
      e.effect.getFormID(),
      Actor.from(e.target),
      ChangeNpcAppearance
    )
  })

  on("effectFinish", (e) => {
    if (!e.effect) return
    OnMaxickSpell(
      e.effect.getFormID(),
      Actor.from(e.target),
      ClearNpcAppearance
    )
  })
  //#endregion

  // ;>========================================================
  // ;>===                REAL TIME EVENTS                ===<;
  // ;>========================================================

  //#region Real time events

  const T = Hotkeys.ListenToS(DxScanCode.PgDown)
  const OnQuickDebug = Hotkeys.ListenToS(DxScanCode.MiddleMouseButton)

  /** Start debugging an `Actor` when pressing a key. */
  const OnDebugNpc = Hotkeys.ListenToS(DxScanCode.End)
  /** Real time decay and catabolism calculations */
  const RTcalc = Misc.UpdateEach(3)

  const Spline = MathLib.CubicSpline([
    { x: 0.1, y: 0 },
    { x: 0.3, y: 0.7 },
    { x: 0.8, y: 0.9 },
  ])

  on("update", () => {
    TestMode.Next(TestMode.GoNext)
    TestMode.Prev(TestMode.GoPrev)
    TestMode.Add10(TestMode.GoAdd10)
    TestMode.Sub10(TestMode.GoSub10)
    TestMode.SlideShow(TestMode.GoSlideShow)

    RTcalc(Player.Calc.Update)

    OnQuickDebug(() => {
      // Player.Calc.Training.OnTrain("OneHanded")
      // Player.QuickDebug.EnterCatabolic()
      // Player.Calc.Training.OnTrain("SEX")
      // Player.QuickDebug.DoSleep()
      // printConsole(`------`)
      // for (let i = 0; i < 1; i += 0.1) {
      //   printConsole(`------`, i, " -- ", Spline(i))
      // }
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
  //#endregion

  printConsole("Max Sick Gains successfully initialized.")
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
    `${evMsg}. Actor: ${b.getName()}. Id: 0x${DebugLib.Log.IntToHex(
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
