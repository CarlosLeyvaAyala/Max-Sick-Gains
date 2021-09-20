Scriptname Maxick___Compatibility Hidden
{Make your mod compatible with Max Sick Gains.}


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

; Returns a variable that lets you hook to events sent by this mod.
Maxick_Events Function HookToEvents() Global
  return _MaxickMain() as Maxick_Events
EndFunction

; Returns a variable that lets you hook to all debugging functions on this mod.
Maxick_Debug Function HookToDebugging() Global
  return _MaxickMain() as Maxick_Debug
EndFunction

; Saves a float value to an internal database.
Function SaveFlt(string addonName, string aKey, float aValue) Global
  Maxick_DB.SaveFlt(_MakeDbPath(addonName, akey), aValue)
EndFunction

; Gets a float value from the internal database. Returns `default` if value was not found.
float Function GetFlt(string addonName, string aKey, float default = 0.0) Global
  return Maxick_DB.GetFlt(_MakeDbPath(addonName, akey), default)
EndFunction


; !  ██╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗ ███████╗    ████████╗██╗  ██╗███████╗███████╗███████╗
; !  ██║██╔════╝ ████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ╚══██╔══╝██║  ██║██╔════╝██╔════╝██╔════╝
; !  ██║██║  ███╗██╔██╗ ██║██║   ██║██████╔╝█████╗         ██║   ███████║█████╗  ███████╗█████╗
; !  ██║██║   ██║██║╚██╗██║██║   ██║██╔══██╗██╔══╝         ██║   ██╔══██║██╔══╝  ╚════██║██╔══╝
; !  ██║╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║███████╗       ██║   ██║  ██║███████╗███████║███████╗
; !  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

; Returns a handle to the main quest for Max Sick Gains.
; For internal use of this script. You don't really need to concern yourself about this.
Quest Function _MaxickMain() Global
  return Game.GetFormFromFile(0xD76, "Max Sick Gains.esp") as Quest
EndFunction

; Converts the addon name and key to a value JContainers can understand.
string Function _MakeDbPath(string addonName, string aKey) Global
  return "addons." + addonName + "." + aKey
EndFunction
