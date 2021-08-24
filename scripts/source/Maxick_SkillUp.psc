Scriptname Maxick_SkillUp extends Quest

Maxick_EventNames Property ev Auto

function OnStoryIncreaseSkill(string aSkill)
  ev.SendPlayerHasTrained(aSkill)
  Stop()
endFunction
