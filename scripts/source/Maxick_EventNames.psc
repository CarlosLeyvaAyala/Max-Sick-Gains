; This script includes some functions to easily communicate with Max Sick Gains.
; Those are listed under the HELPERS section.
;
; Here you will also find all events this mod can send and receive.
;
; All events can be received by you so you can do things according to it, but
; some of them can be also sent by you to alter things inside this mod.
;
; But if you want to send events, it's preferable to do that through the functions
; declared in the HELPERS section; they already send events for you in a quite
; convenient way.
;
; Use functions in Maxick_Compatibility before you can plug to this script.

Scriptname Maxick_EventNames extends Quest

; You will have this script by virtue of having downloaded Mak Sick Gains,
; but if your compiler complains of this not being present, download it from:
; https://github.com/CarlosLeyvaAyala/DM-SkyrimSE-Library/blob/master/scripts/Source/DM_Utils.psc
import DM_Utils


; !  ██╗  ██╗███████╗██╗     ██████╗ ███████╗██████╗ ███████╗
; !  ██║  ██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗██╔════╝
; !  ███████║█████╗  ██║     ██████╔╝█████╗  ██████╔╝███████╗
; !  ██╔══██║██╔══╝  ██║     ██╔═══╝ ██╔══╝  ██╔══██╗╚════██║
; !  ██║  ██║███████╗███████╗██║     ███████╗██║  ██║███████║
; !  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝

; Dummy function to let the Visual Studio Code plugin correctly show documentation for
; all functions below.
;
; Do yourself a favor and dowload it from here:
; https://marketplace.visualstudio.com/items?itemname=joelday.papyrus-lang-vscode
Function _Dummy()
EndFunction

; Skyrim's `Utility.GetCurrentGameTime()` gets time as fractions of a day, where `1`
; means one day, while `0.5` means half a day.
; This function converts Skyrim time to human readable hours, so `0.5` becomes `12`.
;
; Use this to easily change time for functions and events that ask for _human time_.
float Function ToHumanHours(float gameHours)
  return ToRealHours(gameHours)
EndFunction

; Sends an event saying the player has trained an [skill defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
;
; You usually won't need to call this function if you are using standard means to activate
; sex and if you are incrementing skills via `Game.AdvanceSkill()`.
;
; ## List of possible values
;
; - "Alteration"
; - "Block"
; - "Conjuration"
; - "Destruction"
; - "HeavyArmor"
; - "Illusion"
; - "LightArmor"
; - "Marksman" (archery)
; - "OneHanded"
; - "Restoration"
; - "SackL" (large training sack)
; - "SackM" (medium training sack)
; - "SackS" (small training sack)
; - "Sex"
; - "Smithing"
; - "Sneak"
; - "TwoHanded"
;
; Always prefer this function over `Maxick_EventNames.SendTrainingAndActivity()`.
Function SendPlayerHasTrained(string skillName)
  SendModEvent(TRAIN, skillName)
EndFunction

; Sends the mod event to change `gains`.
; **Gains meter will flash**.
;
; - `gainsChange`: How much gains will be added/substracted to player.
Function SendGainsChange(float gainsChange)
  SendModEvent(GAINS_CHANGE, "", gainsChange)
EndFunction

; Sends the mod events to change both `training` and `inactivity`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will flash**, but not the inactivity one.
;
; -  See `Maxick_EventNames.SendTrainingChange()` for details.
; -  See `Maxick_EventNames.SendActivityChange()` for details.
Function SendTrainingAndActivity(string skillName, float trainingChange, float activityChange)
  SendTrainingChange(skillName, trainingChange)
  SendActivityChange(skillName, activityChange)
EndFunction

; Sends the mod event to change `training`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will flash**.
;
; - `skillName`: The skill that went up/down. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
;    I'm talking about this:
;         "This string contains ""double quotes"" and it's invalid".
;         "This string is totally valid".
; - `trainingChange`: How much training will be added/substracted to player.
;
; ## Numbers sent by Max Sick Gains
; Use this table for reference on what numbers you can send with this function.
;
; | Skill       | Training |
; |-------------|----------|
; | Alteration  | 0.1      |
; | Block       | 0.5      |
; | Conjuration | 0.01     |
; | Destruction | 0.07     |
; | HeavyArmor  | 0.5      |
; | Illusion    | 0.01     |
; | LightArmor  | 0.15     |
; | Marksman    | 0.1      |
; | OneHanded   | 0.35     |
; | Restoration | 0.1      |
; | SackL       | 1.5      |
; | SackM       | 1        |
; | SackS       | 0.7      |
; | Sex         | 0.001    |
; | Smithing    | 0.1      |
; | Sneak       | 0.15     |
; | TwoHanded   | 0.5      |
Function SendTrainingChange(string skillName, float trainingChange)
  SendModEvent(TRAINING_CHANGE, skillName, trainingChange)
EndFunction

; Sends the mod event to change `inactivity`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will NOT flash**.
;
; - `skillName`: The skill that went up/down. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
;    I'm talking about this:
;         "This string contains ""double quotes"" and it's invalid".
;         "This string is totally valid".
; - `activityChange`: How much activity will be added/substracted ***IN HUMAN HOURS***. Send positive values to simulate training; negative values for simulating inactivity.
;
; ## Numbers sent by Max Sick Gains
; Use this table for reference on what numbers you can send with this function.
;
; | Skill       | Activity |
; |-------------|----------|
; | Alteration  | 7.2      |
; | Block       | 19.2     |
; | Conjuration | 7.2      |
; | Destruction | 7.2      |
; | HeavyArmor  | 19.2     |
; | Illusion    | 7.2      |
; | LightArmor  | 19.2     |
; | Marksman    | 19.2     |
; | OneHanded   | 19.2     |
; | Restoration | 7.2      |
; | SackL       | 48       |
; | SackM       | 36       |
; | SackS       | 24       |
; | Sex         | 4.8      |
; | Smithing    | 19.2     |
; | Sneak       | 19.2     |
; | TwoHanded   | 19.2     |
;
; All these numbers are time in human hours, not Skyrim hours.
; This means large training sacks (`SackL`) are worth 48 hours of activity; ie. two days.
;
; Sex is so "low" because that number of hours is added at each single change of
; sexual position and when finishing the sex act, so just one session can easily
; rake up to 20+ hours worth of activity.
Function SendActivityChange(string skillName, float activityChange)
  SendModEvent(ACTIVITY_CHANGE, skillName, activityChange)
EndFunction

; Sends an event after sleeping.
;
; - `humanHoursSlept`: Time slept ***IN HUMAN HOURS***.
;
; Use this if your mod simulates sleeping by doing some fade to black scene or something.
Function SendSleep(float humanHoursSlept)
  SendModEvent(SLEEP, "", humanHoursSlept)
EndFunction


; !  ██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗     ██████╗ ███╗   ██╗██╗  ██╗   ██╗
; !  ██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝    ██╔═══██╗████╗  ██║██║  ╚██╗ ██╔╝
; !  ██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗      ██║   ██║██╔██╗ ██║██║   ╚████╔╝
; !  ██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝      ██║   ██║██║╚██╗██║██║    ╚██╔╝
; !  ██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗    ╚██████╔╝██║ ╚████║███████╗██║
; !  ╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝     ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝

; ***NEVER*** SEND THESE EVENTS YOURSELF with `SendModEvent()`.
; These aren't meant to be sent by addon creators and you may end up breaking this mod.
;
; It's completely secure (and encouraged) to listen to these events by using
; `RegisterForModEvent()`, though.
;
; https://www.creationkit.com/index.php?title=RegisterForModEvent_-_Form

;------------------------------------------------------------------------------------

string Property JOURNEY_AVERAGE = "Maxick_JourneyByAverage" AutoReadOnly
{
**Activation**: When `gains` are set.

- `float numArg`: Number between `[0..1]`.
Average of the total percent of the player journey that the other methods reported.

### Remarks

- Use this to know how much the player has advanced towards their fitness goals.
- This is the preferred method for gauging player progress.

### Sample usage:

```
Event OnJourneyAverage(string _, string __, float journey, Form ___)
  Log("Journey average sucessfully got: " + journey)
EndEvent
```
}

;------------------------------------------------------------------------------------

string Property JOURNEY_DAYS = "Maxick_JourneyByDays" AutoReadOnly
{
**Activation**: When `gains` are set.

`float numArg`: Total percent of the player journey (based on Player Stages).

- Use this to know how much the player has advanced towards their fitness goals.
}

;------------------------------------------------------------------------------------

string Property JOURNEY_STAGE = "Maxick_JourneyByStage" AutoReadOnly
{
**Activation**: When `gains` are set.


`float numArg`: Total percent of the player journey (based on Player Stages).

- Use this to know how much the player has advanced towards their fitness goals.
}

;------------------------------------------------------------------------------------

string Property GAINS = "Maxick_Gains" AutoReadOnly
{
**Activation**: When `gains` are set.

`float numArg`: The new value for `gains`: `[0..100]`.

- Use this for reference. So you can do things based on current `gains`.
- This event adjusts the widget value display.
}

;------------------------------------------------------------------------------------

string Property TRAINING = "Maxick_Training" AutoReadOnly
{**Activation**: When `training` is set.
***This refers to the `training` variable, not the act of training***, which is what `TRAIN` is for.

`float numArg`: The new value for `training`: `[0..12]`.

- Use this for reference. So you can do things based on current `training`.
- This event adjusts the widget value display.}

;------------------------------------------------------------------------------------

string Property INACTIVITY = "Maxick_Inactivity" AutoReadOnly
{**Activation**: When `inactivity` is set.

`float numArg`: The new value for `inactivity` `[0..100]`.

- This event adjusts the widget value display.}

;------------------------------------------------------------------------------------

string Property PLAYER_STAGE_DELTA = "Maxick_PlayerStageDelta" AutoReadOnly
{**Activation**: When a new `playerStage` is set.

`int numArg`: How many stages have changed. Negative when regressing.

- This event makes the widget to show a message saying that Player Stage has changed.
}

;------------------------------------------------------------------------------------

string Property PLAYER_STAGE = "Maxick_PlayerStage" AutoReadOnly
{**Activation**: When a new `playerStage` is set.

`int numArg`: The new Player Stage.
}

;------------------------------------------------------------------------------------

string Property CATABOLISM_START = "Maxick_CatabolismStart" AutoReadOnly
{**Activation**: When the player enters catabolic state and starts to lose gains.

`int numArg = 1`. Use this to manage this event and `CATABOLISM_END` with only one event.

- This event tells the widget to flash loses every step (affected by `UPDATE_INTERVAL`).
}

;------------------------------------------------------------------------------------

string Property CATABOLISM_END = "Maxick_CatabolismEnd" AutoReadOnly
{**Activation**: When the player exits catabolic state by training.

`numArg = 0`. Use this to manage this event and `CATABOLISM_START` with only one event.
}

;------------------------------------------------------------------------------------

string Property CELL_CHANGE = "Maxick_CellChange" AutoReadOnly
{
**Activation**: When player enters a new cell.

- I use this event to apply appearance settings to NPCs.
- It may be useful to you for other reasons, though.
}

;------------------------------------------------------------------------------------

string Property LOGGING_LVL = "Maxick_LoggingLvl" AutoReadOnly
{**Activation**: When the logging level is set.

`int numArg`: These are the possible values:
1. None
2. Critical - Errors and important things.
3. Info - Meant to be detailed info for players.
4. Verbose - Extremely detailed info for debugging purposes. Not really meant for players.

You are unlikely to need this event, but I do.}

;------------------------------------------------------------------------------------

string Property UPDATE_INTERVAL = "Maxick_UpdateInterval" AutoReadOnly
{**Activation**: When the update interval for calculating losses is set.
`int numArg`: The value for the update interval.

You are unlikely to need this event, but I do.}

;------------------------------------------------------------------------------------


; !  ███████╗███████╗███╗   ██╗██████╗      █████╗ ███╗   ██╗██████╗     ██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗
; !  ██╔════╝██╔════╝████╗  ██║██╔══██╗    ██╔══██╗████╗  ██║██╔══██╗    ██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝
; !  ███████╗█████╗  ██╔██╗ ██║██║  ██║    ███████║██╔██╗ ██║██║  ██║    ██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗
; !  ╚════██║██╔══╝  ██║╚██╗██║██║  ██║    ██╔══██║██║╚██╗██║██║  ██║    ██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝
; !  ███████║███████╗██║ ╚████║██████╔╝    ██║  ██║██║ ╚████║██████╔╝    ██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗
; !  ╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝

; You are better using the functions provided by this file if you want to send these events,
; but here's the whole reference, so you know what they do.

string Property TRAIN = "Maxick_Train" AutoReadOnly
{**Activation**: When leveled up a skill that contributes to training.

`strArg`: The skill that went up.

- You can send events that count as training, and thus, affecting inactivity.
- Make sure to send an [event defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
}

string Property TRAINING_CHANGE = "Maxick_TrainChange" AutoReadOnly
{**Activation**: Once `training` and `inactivity` have both been defined and will be sent to being applied on the player.

`strArg`: The skill that went up/down. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
`numArg`: How much training will be added/substracted.

- You can send events that directly affect training without affecting inactivity, so you should send this and `ACTIVITY_CHANGE` in tandem.
- Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
- This event makes the widget flash.
}

string Property ACTIVITY_CHANGE = "Maxick_ActivityChange" AutoReadOnly
{**Activation**: Once `training` and `inactivity` have both been defined and will be sent to being applied on the player.

`strArg`: The skill that went up. ***NEVER SEND STRINGS THAT CONTAIN DOUBLE QUOTES***.
`numArg`: How much inactivity will be added/substracted (***HUMAN HOURS***). Send a positive value to simulate training. Negative to simulate inactivity.

- You can send events that directly affect `training` without affecting `inactivity`, so you should send this and `TRAINING_CHANGE` in tandem.
- Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
- This event **DOES NOT** make the widget flash.
}

string Property GAINS_CHANGE = "Maxick_GainsChange" AutoReadOnly
{**Activation**: When gains have been calculated but aren't yet set.

`numArg`: The change value for gains. Positive if gained. Negative when lost.

- You can send your own values to affect player gains without training.
- This event makes the widget flash.
}

string Property SLEEP = "Maxick_Sleep" AutoReadOnly
{**Activation**: When woken up.

`numArg`: Number of hours slept ***IN HUMAN HOURS***, NOT game time.

- You can simulate the player sleeping by sending this event, thus making gains calculations on sleeping.}
