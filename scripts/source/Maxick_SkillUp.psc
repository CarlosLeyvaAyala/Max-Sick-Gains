Scriptname Maxick_SkillUp extends Quest

Maxick_Player Property PcHandler  Auto

function OnStoryIncreaseSkill(string aSkill)
  PcHandler.TrainSkill(aSkill)
  Stop()
endFunction
