import {
  Player as P,
  getBaseName,
  isActorTypeNPC,
  isPlayer,
  waitActor,
} from "DmLib/Actor"
import * as HK from "DmLib/Hotkeys"
import * as Log from "DmLib/Log"
import { randomRange } from "DmLib/Math"
import { tryE, wait } from "DmLib/Misc"
import { updateEach } from "Misc"
import { ScanCellNPCs } from "PapyrusUtil/MiscUtil"
import { MaxickSpell, MaxickSpellFx, playerId } from "constants"
import {
  ActiveEffectApplyRemoveEvent,
  Actor,
  ActorBase,
  Armor,
  CellAttachDetachEvent,
  Debug,
  EquipEvent,
  Game,
  SlotMask,
  Utility,
  on,
  once,
} from "skyrimPlatform"
import * as AnimHooks from "./animations/constants"
import { HookAnims, LogAnims } from "./animations/hooks"
import {
  ClearAppearance,
  EquipPizzaHandsFix,
  FixGenitalTextures,
} from "./appearance/appearance"
import {
  ChangeMuscleDef,
  ChangeAppearance as ChangeNpcAppearance,
  ClearAppearance as ClearNpcAppearance,
} from "./appearance/npc"
import { Player, TestMode } from "./appearance/player"
import { PlayerJourney } from "./appearance/player/journey"
import * as JourneyManager from "./appearance/shared/dynamic/journey/manager"
import { KnownNpcData, knownNPCs, mcm } from "./database"
import { LogE, LogI, LogIT, LogN, LogV } from "./debug"
import { GAME_INIT } from "./events/events_hidden"
import { TRAIN } from "./events/maxick_compatibility"
import { loadAlternateData } from "./types/exported"
import { logBanner } from "./appearance/common"

// const initK = ".DmPlugins.Maxick.init"
// const MarkInitialized = () => JDB.solveBoolSetter(initK, true, true)
// const WasInitialized = () => JDB.solveBool(initK, false)

export function main() {
  LogN("|".repeat(100))
  LogN("Initializing Max Sick Gains.")
  let playerJourney: PlayerJourney | null = null

  once("update", () => {
    initializeJourneys()
  })

  function initializeJourneys() {
    loadAlternateData() // FIX: Delete when ready
    JourneyManager.initialize()
    logBanner("Player is ready to get processed", LogN, "+")
    // Kickstart real time calculations
    playerJourney = JourneyManager.player()
    AnimHooks.setPlayerJourney(playerJourney)
  }

  // ;>========================================================
  // ;>===                 PLAYER EVENTS                  ===<;
  // ;>========================================================

  //#region Player events
  if (!mcm.testingMode.enabled) HookAnims()
  if (mcm.logging.anims) LogAnims()

  on("sleepStop", (_) => {
    JourneyManager.onSleepEnd()
    // Sleep.OnEnd()
  })

  on("sleepStart", (_) => {
    JourneyManager.onSleepStart()
    // Sleep.OnStart()
  })

  let allowInit = true

  /** Needs to be handled apart from hot reloading because New/Load Game menu
   * option triggers both, but reloading a save while playing won't trigger
   * hot reload capabilities.
   */
  on("loadGame", () => {
    LogV("||| Game loaded |||")
    if (!allowInit) Initialize()
    initializeJourneys()
    // This needs to be called because reloading in situ (like after being killed)
    // requires to initialize NPCs again.
    InitializeSurroundingNPCs()
  })

  /** Hot reload management.*/
  once("update", () => {
    CheckExpectedEsps()
    const rm = Game.getModByName("RaceMenu.esp")
    if (!rm)
      Debug.messageBox("This mod needs Race Menu installed for it to work")
    if (allowInit) Initialize()
  })

  /** Changed to were-something. */
  on("switchRaceComplete", (e) => {
    if (isPlayer(e.subject)) Player.Appearance.Change()
  })

  on("modEvent", (e) => {
    const Exe = (f: () => void) => {
      LogI(`Mod event recieved. ${e.eventName}.`)
      f()
    }

    if (e.eventName === TRAIN)
      return Exe(() => {
        if (!mcm.testingMode.enabled) Player.Calc.Training.OnTrain(e.strArg)
      })

    if (e.eventName === GAME_INIT) return Exe(Initialize)
  })

  on("niNodeUpdate", (e) => {
    if (!e.reference) return
    const a = Actor.from(e.reference)
    if (!isActorTypeNPC(a)) return

    if (isPlayer(a)) {
      Player.Appearance.ChangeMuscleDef()
      return
    }
    ChangeMuscleDef(a)
  })

  const Initialize = () => {
    wait(0.2, () => {
      if (!P().is3DLoaded()) return
      Player.Init()
      ClearAppearance(P()) // Avoid CTD
      Player.Appearance.Change()
      allowInit = false
    })
  }
  //#endregion

  // ;>========================================================
  // ;>===             PLAYER AND NPC EVENTS              ===<;
  // ;>========================================================

  //#region Player and NPC events
  on("equip", (e) => {
    Actor.from(e.actor)?.addSpell(MaxickSpell(), false)
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

  const useSPID = true // TODO: Make this a configurable option

  // Execute inmediately after (re)loading a game to try to avoid having
  // unset NPCs when reloading a game
  once("cellAttach", (e) => DeTach("Attached", e, ChangeNpcAppearance))

  // Not as reliable as SPID, but can be used for a backup method in
  // case SPID doesn't work, like v5.2.0 on SE.
  if (!useSPID) {
    on("cellAttach", (e) => DeTach("Attached", e, ChangeNpcAppearance))
    on("cellDetach", (e) => DeTach("Detached", e, ClearNpcAppearance))
  }

  // Right now, NPC appearance is set by applying a Spell via SPID, since it's
  // the most reliable method to apply them settings as soon as they spawn.
  // That spell is empty and does nothing. All the work is done here.
  if (useSPID) {
    on("effectStart", (e) => ExecuteSPIDSpell(e, ChangeNpcAppearance))
    on("effectFinish", (e) => ExecuteSPIDSpell(e, ClearNpcAppearance))
  }
  //#endregion

  // ;>========================================================
  // ;>===                REAL TIME EVENTS                ===<;
  // ;>========================================================

  //#region Real time events

  /** Resets an `Actor` when pressing a key. */
  const h = mcm.actors
  const OnResetNpc = HK.ListenTo(HK.FromValue(h.hkReset))
  const OnResetNearby = HK.ListenTo(HK.FromValue(h.hkResetNearby))
  /** Real time decay and catabolism calculations */
  const RTcalc = updateEach(3)
  const RTcalc2 = updateEach(3)

  on("update", () => {
    TestMode.Next(TestMode.GoNext)
    TestMode.Prev(TestMode.GoPrev)
    TestMode.Add10(TestMode.GoAdd10)
    TestMode.Sub10(TestMode.GoSub10)
    TestMode.SlideShow(TestMode.GoSlideShow)

    // RTcalc(Player.Calc.Update)
    RTcalc2(() => {
      playerJourney?.updateRT()
    })
    OnResetNpc(ResetNPC)

    OnResetNearby(InitializeSurroundingNPCs)
  })
  //#endregion

  LogN("Max Sick Gains successfully initialized.")
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
  if (!target || !IsMaxickSpellFx(spellId)) return

  try {
    const t = Math.random() * 0.04 + 0.01
    waitActor(target, t, (a) => {
      if (!isActorTypeNPC(a)) return // Should have been done by SPID
      DoSomething(a)
    })
  } catch (error) {
    LogE(error instanceof Error ? error.message : String(error))
  }
}

function IsMaxickSpellFx(spellId: number) {
  return MaxickSpellFx()?.getFormID() === spellId
}

/** Solves wrong genital textures due to texture overrides.
 *
 * @remarks
 * Can be used to solve the Pizza Hands Syndrome as well.
 *
 * @param e Event variable.
 * @param evMsg Message to log.
 * @param DoSomething An extra function to execute.
 */
function OnUnEquip(
  e: EquipEvent,
  evMsg: string,
  DoSomething?: (actor: Actor, slot: number) => void
) {
  // Basic validity checks
  const a = Actor.from(e.actor)
  if (!a) return
  const b = a.getLeveledActorBase()
  const armor = Armor.from(e.baseObj)
  if (!isActorTypeNPC(a) || !b || !armor) return

  // Only cares for cuirasses and gauntlets
  const sl = armor.getSlotMask()
  if (sl !== SlotMask.Body && sl !== SlotMask.Hands) return

  LogUnEquip(a, b, sl, evMsg, e)

  // Wait before fixing things because Skyrim Platform is TOO fast <3.
  waitActor(a, 0.001, (act) => {
    if (sl === SlotMask.Body) FixGenitalTextures(act)
    if (DoSomething) DoSomething(act, sl)
  })
}

function LogUnEquip(
  a: Actor,
  b: ActorBase,
  sl: number,
  evMsg: string,
  e: EquipEvent
) {
  LogV(
    `${evMsg}. Actor: ${b.getName()}. Id: 0x${Log.IntToHex(
      a.getFormID()
    )}. Object: ${e.baseObj.getName()}. Slot: ${sl}`
  )
}

const npcWaitTime = () => randomRange(0.005, 0.05)

function DeTach(
  evt: string,
  e: CellAttachDetachEvent,
  DoSomething: (target: Actor | null) => void
) {
  tryE(() => {
    const a = Actor.from(e.refr)
    if (!a || !isActorTypeNPC(a) || a.isDisabled()) return

    waitActor(a, npcWaitTime(), (actor) => {
      LogV(`${evt} actor: ${getBaseName(actor)}`)
      DoSomething(actor)
    })
  }, LogE)
}

function ResetNPC() {
  let r = LogIT("Getting reference at crosshair", Game.getCurrentCrosshairRef())
  if (!r)
    r = LogIT(
      "No reference found at crosshair. Trying console one",
      Game.getCurrentConsoleRef()
    )
  const a = Actor.from(r)
  if (!a || !isActorTypeNPC(a)) return

  if (isPlayer(a)) Player.Appearance.Change()
  else ChangeNpcAppearance(a)
}

function InitializeSurroundingNPCs() {
  logBanner("Initializing surrounding NPCs", LogN, "/")

  const f = async () => {
    await Utility.wait(0.54)
    const actors = ScanCellNPCs(Game.getPlayer(), 7000, null, false).map((a) =>
      a?.getFormID()
    )

    for (const aId of actors) {
      await Utility.wait(0.05)
      if (!aId) return
      const a = Actor.from(Game.getFormEx(aId))
      if (!a || !a.is3DLoaded() || aId === playerId || !isActorTypeNPC(a))
        return
      LogN(
        `Setting appearance to nearby actor: ${a.getBaseObject()?.getName()}`
      )
      // ClearAppearance(a) // Avoid CTD
      ChangeNpcAppearance(a)
    }
  }
  f()
}

function ExecuteSPIDSpell(
  e: ActiveEffectApplyRemoveEvent,
  DoSomething: (target: Actor | null) => void
) {
  const a = Actor.from(e.target)
  if (!e.effect || !a) return
  OnMaxickSpell(e.effect.getFormID(), a, DoSomething)
}

export function CheckExpectedEsps() {
  const PrintNames = (a: { [key: string]: KnownNpcData }) => {
    for (const id in a) LogE(a[id].fullName)
  }

  for (const esp in knownNPCs)
    if (!Game.isPluginInstalled(esp)) {
      const msg = `"${esp}" is not installed. These Known NPCs will not look as expected:`
      LogE(msg)
      PrintNames(knownNPCs[esp])
    }
}
