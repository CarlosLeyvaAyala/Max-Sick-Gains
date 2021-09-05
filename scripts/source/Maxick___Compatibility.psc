Scriptname Maxick___Compatibility Hidden
{Make your mod compatible with Max Sick Gains}

; Skyrim's `Utility.GetCurrentGameTime()` gets time as fractions of a day, where `1`
; means one day, while `0.5` means half a day.
; This function converts Skyrim time to human readable hours, so `0.5` becomes `12`.
;
; Use this to easily change time for functions and events that ask for _human time_.
float Function ToHumanHours(float gameHours) Global
  ; You will have DM_Utils installed by virtue of having downloaded the Mak Sick Gains SDK.
  return DM_Utils.ToRealHours(gameHours)
EndFunction

; Converts human readable hours to fractions of a day, which is what Skyrim actually
; understands.
;
; For example, 12 gets converted to 0.5 (half a day).
float Function ToSkyrimHours(float humanHours) Global
  return DM_Utils.ToGameHours(humanHours)
EndFunction

Maxick_Events Function HookToEvents() Global
  return _MaxickMain() as Maxick_Events
EndFunction

Maxick_Debug Function HookToDebugging() Global
  return _MaxickMain() as Maxick_Debug
EndFunction

Quest Function _MaxickMain() Global
  return Game.GetFormFromFile(0xD76, "Max Sick Gains.esp") as Quest
EndFunction
