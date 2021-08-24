; All events can be received by you so you can do things according to it, but
; some of them can be also sent by you to alter things inside this mod.
; Use those kind of events to make your own addons or adding compatibility to
; your mod if you want.
;
; This script also includes some functions to easily send your own mod events to
; your convenience.

Scriptname Maxick_EventNames extends Quest

; You will have this script by virtue of having downloaded Mak Sick Gains,
; but if your compiler complains of this not being present, download it from:
; https://github.com/CarlosLeyvaAyala/DM-SkyrimSE-Library/blob/master/scripts/Source/DM_Utils.psc
import DM_Utils

;>========================================================
;>===        EVENTS YOU CAN SEND AND RECEIVE         ===<;
;>========================================================

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

`strArg`: The skill that went up/down.
`numArg`: How much training will be added/substracted.

- You can send events that directly affect training without affecting inactivity, so you should send this and `INACTIVITY_CHANGE` in tandem.
- Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
- This event makes the widget flash.
}

string Property INACTIVITY_CHANGE = "Maxick_InactivityChange" AutoReadOnly
{**Activation**: Once `training` and `inactivity` have both been defined and will be sent to being applied on the player.

`strArg`: The skill that went up.
`numArg`: How much inactivity will be added/substracted (***HUMAN HOURS***). Send a negative value to simulate training.

- You can send events that directly affect training without affecting training, so you should send this and `TRAINING_CHANGE` in tandem.
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

;>========================================================
;>===          EVENTS YOU CAN ONLY RECEIVE           ===<;
;>========================================================

; ***NEVER*** SEND THIS EVENTS YOURSELF with `SendModEvent()`.
; These aren't meant to be sent by addon creators and you may end up breaking this mod.
; It's completely secure (and encouraged) to listen to these events using
; `RegisterForModEvent()`, though.

string Property GAINS = "Maxick_Gains" AutoReadOnly
{**Activation**: When `gains` are set.

`numArg`: The new value for `gains`: `[0..100]`.

- Use this for reference. So you can do things based on current `gains`.
- This event adjusts the widget value display.}

string Property TRAINING = "Maxick_Training" AutoReadOnly
{**Activation**: When `training` is set.
***This refers to the `training` variable, not the act of training***, which is what `TRAIN` is for.

`numArg`: The new value for `training`: `[0..12]`.

- Use this for reference. So you can do things based on current `training`.
- This event adjusts the widget value display.}

string Property INACTIVITY = "Maxick_Inactivity" AutoReadOnly
{**Activation**: When `inactivity` is set.

`numArg`: The new value for `inactivity` `[0..100]`.

- This event adjusts the widget value display.}

string Property CATABOLISM_START = "Maxick_CatabolismStart" AutoReadOnly
{**Activation**: When the player enters catabolic state and starts to lose gains.

`numArg`: `1`. Use this to manage this event and `CATABOLISM_END` with only one event.

- This event tells the widget to flash loses every step (affected by `UPDATE_INTERVAL`).
}

string Property CATABOLISM_END = "Maxick_CatabolismEnd" AutoReadOnly
{**Activation**: When the player exits catabolic state by training.

`numArg`: `0`. Use this to manage this event and `CATABOLISM_START` with only one event.
}

string Property UPDATE_INTERVAL = "Maxick_UpdateInterval" AutoReadOnly
{**Activation**: When the update interval for widget/losses is read from file.
`numArg`: The value for the update interval.

You are unlikely to need this, but I do.}


;>========================================================
;>===                HELPER FUNCTIONS                ===<;
;>========================================================

; Dummy function to let Visual Studio Code plugin correctly show documentation for
; all functions below
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

; Sends the mod event to change `training`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will flash**.
;
; - `skillName`: The skill that went up/down.
; - `trainingChange`: How much training will be added/substracted to player.
Function SendTrainingChange(string skillName, float trainingChange)
  SendModEvent(TRAINING_CHANGE, skillName, trainingChange)
EndFunction

; Sends the mod event to change `inactivity`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will NOT flash**.
;
; - `skillName`: The skill that went up/down.
; - `inactivityChange`: How much inactivity will be added/substracted ***IN HUMAN HOURS***. Send negative values to simulate training; positive values for simulating inactivity.
Function SendInactivityChange(string skillName, float inactivityChange)
  SendModEvent(INACTIVITY_CHANGE, skillName, inactivityChange)
EndFunction

; Sends the mod events to change both `training` and `inactivity`.
; Use this when you want to send an event not [defined by this mod](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/SKSE/Plugins/JCData/lua/maxick/skill.lua).
; **Training meter will flash**, but not the inactivity one.
;
; - `skillName`: The skill that went up/down.
; - `trainingChange`: How much training will be added/substracted to player.
; - `inactivityChange`: How much inactivity will be added/substracted ***IN HUMAN HOURS***. Send negative values to simulate training; positive values for simulating inactivity.
Function SendTrainingAndInactivity(string skillName, float trainingChange, float inactivityChange)
  SendTrainingChange(skillName, trainingChange)
  SendInactivityChange(skillName, inactivityChange)
EndFunction

; Sends an event after sleeping.
; - `humanHoursSlept`: Time slept ***IN HUMAN HOURS***.
Function SendSleep(float humanHoursSlept)
  SendModEvent(SLEEP, "", humanHoursSlept)
EndFunction
