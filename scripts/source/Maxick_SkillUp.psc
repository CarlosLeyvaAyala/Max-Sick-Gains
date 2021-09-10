Scriptname Maxick_SkillUp extends Quest

Maxick_Events Property ev Auto
Maxick_Debug Property md Auto

function OnStoryIncreaseSkill(string aSkill)
  md.LogVerb("OnStoryIncreaseSkill: " + aSkill)
  ev.SendPlayerHasTrained(aSkill)
  Stop()
endFunction
