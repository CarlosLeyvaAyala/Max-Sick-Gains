Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}

Import JValue
Import DM_Utils
Import Maxick_Utils

Actor Property player Auto
Maxick_Player Property PcHandler Auto
{Handles everything Player related.}
Maxick_ActorAppearance Property looksHandler Auto
{Handles everything appearance related.}
Maxick_Debug Property md Auto
{Handles everything debgging related.}
Maxick_Widget Property widget Auto
{Widget.}
Maxick_Events Property ev Auto

Maxick_Events_Hidden Property evh Auto

Spell Property ChangeCellSpell Auto

Event OnInit()
  OnGameReload()
  SendModEvent(evh.GAME_INIT)
EndEvent

; These functions are called sequentially and not hooked as callbacks because we want to
; make sure these settings are initializated in this precise order.
Function OnGameReload()
  _RegisterEvents()
  PcHandler.OnGameReload()
  widget.OnGameReload()
  SendModEvent(evh.GAME_RELOADED)
EndFunction

;>========================================================
;>===                     EVENTS                     ===<;
;>========================================================

; Registers events needed for this mod to work.
Function _RegisterEvents()
  _RegisterForSex()
EndFunction

; Captures when player is having sex.
Function _RegisterForSex()
  If SexLabExists()
    ; RegisterForModEvent("AnimationStart", "SexLabEvent")
    RegisterForModEvent("StageEnd", "SexLabEvent")
    RegisterForModEvent("AnimationEnd", "SexLabEvent")
  EndIf
  RegisterForModEvent("ostim_animationchanged", "OStimEvent")
  RegisterForModEvent("ostim_end", "OStimEvent")
EndFunction

; TODO: Activate again when I've figured out OStim dependencies
; OStim integration.
; Event OStimEvent(string _, string __, float ___, form ____)
;   If OUtils.GetOStim().IsActorActive(player)
;     md.LogInfo("OStim event detected")
;     SendModEvent(ev.TRAIN, "Sex")
;   EndIf
; EndEvent

; Sexlab integration.
Event SexLabEvent(string _, string __, float ___, form sender)
  sslThreadController c = sender as sslThreadController
  If c && c.HasPlayer
    md.LogInfo("SexLab event detected")
    SendModEvent(ev.TRAIN, "Sex")
  EndIf
EndEvent
