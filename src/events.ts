import { Game } from "skyrimPlatform"

/** Sends an event saying gains have been set.
 * @remarks
 * This event doesn't make the widget flash.
 *
 * @param gains New gains.
 */
export function SendGains(gains: number) {
  Game.getPlayer()?.sendModEvent("Maxick_Gains", "", gains)
}

export function SendInactivity(percent: number) {
  Game.getPlayer()?.sendModEvent("Maxick_Inactivity", "", percent)
}
