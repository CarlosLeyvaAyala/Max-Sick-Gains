Scriptname Maxick_iWantElement extends Quest
{ Simplify iWant calls }

iWant_Widgets iWidgets

int Property handle = -1 Auto
{ iWant handle. Needed for manipulation. }

bool Property IsVisible = true Auto
bool Property CanToggleVisibility = true Auto

; Start out of view, then wait for the data coming from typescript
int Property X = 1000 Auto 
int Property Y = 1000 Auto

; Moves element to XY without delay.
Function MoveToXY(float seconds = 0.1, String easingClass = "none", String easingMethod = "none")
  iWidgets.doTransitionByTime(handle, X, seconds, "x", easingClass, easingMethod)
  iWidgets.doTransitionByTime(handle, Y, seconds, "y", easingClass, easingMethod)
EndFunction

Function Hide(float seconds = 1.0)
  _ChangeAlpha(0, seconds)
EndFunction

Function Unhide(float seconds = 1.0)
  _ChangeAlpha(100, seconds)
EndFunction

Function ToggleVisibility(float seconds = 1.0)
  If IsVisible
    Hide(seconds)
  Else
    Unhide(seconds)
  EndIf
EndFunction

Function _ChangeAlpha(int value, float seconds)
  iWidgets.doTransitionByTime(handle, value, seconds, "alpha", "regular", "easeInOut")
EndFunction