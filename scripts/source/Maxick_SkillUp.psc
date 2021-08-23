Scriptname Maxick_SkillUp extends Quest

Maxick_EventNames Property ev Auto

function OnStoryIncreaseSkill(string aSkill)
  SendModEvent(ev.TRAIN, aSkill)
  ; SendModEvent("Maxick_Train", aSkill)
  Stop()
endFunction
