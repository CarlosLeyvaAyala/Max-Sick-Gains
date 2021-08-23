Scriptname Maxick_Utils Hidden

; Path to mod configuration folder.
string Function cfgDir() Global
  return "Data/SKSE/Plugins/Maxick/"
EndFunction

; Path to configuration file generated by _Max Sick Gains.exe_.
string Function genCfg() Global
  return cfgDir() + "genCfg.json"
EndFunction

; Path to female sliders file.
string Function femSliders() Global
  return cfgDir() + "fem-sliders.json"
EndFunction

; Path to male sliders file.
string Function manSliders() Global
  return cfgDir() + "man-sliders.json"
EndFunction

bool Function PapyrusUtilExists() Global
  Return PapyrusUtil.GetVersion() > 1
EndFunction

bool Function SexLabExists() Global
  Return game.IsPluginInstalled("SexLab.esm")
EndFunction

bool Function NiOverrideExists() Global
  Return NiOverride.GetScriptVersion() > 0 && SKSE.GetPluginVersion("skee") >= 1
EndFunction

bool Function JContainersExists() Global
  Return JContainers.isInstalled()
EndFunction
