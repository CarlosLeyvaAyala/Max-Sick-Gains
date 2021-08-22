Scriptname Maxick_SkillUp extends Quest

function OnStoryIncreaseSkill(string aSkill)
  SendModEvent("Maxick_Train", aSkill)
  Stop()
endFunction
