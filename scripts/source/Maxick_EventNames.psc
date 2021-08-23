Scriptname Maxick_EventNames extends Quest

;>========================================================
;>===        EVENTS YOU CAN SEND AND RECEIVE         ===<;
;>========================================================

string Property TRAIN = "Maxick_Train" AutoReadOnly
{**Activation**: When training.
`strArg`: The skill that went up.

You can send events that count as training, and thus, affecting inactivity.}

string Property SLEEP = "Maxick_Sleep" AutoReadOnly
{**Activation**: When woken up.
`numArg`: Number of hours slept in human hours, NOT game time.

You can simulate the player sleeping by sending this event.}

string Property GAINS_DELTA = "Maxick_GainsDelta" AutoReadOnly
{**Activation**: When gains have been calculated but aren't yet set.
`numArg`: The delta (change) for gains. Positive if gained. Negative when lost.

You can send your own values to affect player gains without training.}

;>========================================================
;>===          EVENTS YOU CAN ONLY RECEIVE           ===<;
;>========================================================

string Property UPDATE_INTERVAL = "Maxick_UpdateInterval" AutoReadOnly
{**Activation**: When the update interval for widget/losses is read from file.
`numArg`: The value for the update interval.

You are unlikely to need this, but I do.}

string Property GAINS = "Maxick_Gains" AutoReadOnly
{**Activation**: When gains are set.
`numArg`: The new value for gains `[0..100]`.

Use this for reference. So you can do things based on current gains.}
