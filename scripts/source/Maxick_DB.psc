Scriptname Maxick_DB Hidden
{
  JContainers persistent in-memory database functions.

  This script isn't meant to be used by addon creators.
}

; Saves the database contents for this mod to a file in the JContainers user directory
; (usually {User}\Documents\My Games\Skyrim Special Edition\JCUser\\).
;
; Use this for debugging purposes.
Function SaveToFile(string filename, string subPath = "") Global
  string path = _GetDbObjPath(subPath)
  DM_Utils.LuaDebugTable(JDB.solveObj(path), filename)
EndFunction

; Gets the path for the DB key that will be saved to file.
string Function _GetDbObjPath(string subPath) Global
  string sp
  If subPath != ""
    sp = "." + subPath
  EndIf
  return ".maxick" + sp
EndFunction

; Returns the path to a key.
string Function _Path(string aKey) Global
  return ".maxick." + aKey
EndFunction

; Saves a float.
Function SaveFlt(string aKey, float aValue) Global
  JDB.solveFltSetter(_Path(aKey), aValue, true)
EndFunction

; Gets a float. Returns `default` if key was not found.
float Function GetFlt(string aKey, float default = 0.0) Global
  return JDB.solveFlt(_Path(aKey), default)
EndFunction

; Saves an int.
Function SaveInt(string aKey, int aValue) Global
  JDB.solveIntSetter(_Path(aKey), aValue, true)
EndFunction

; Gets an int. Returns `default` if key was not found.
int Function GetInt(string aKey, int default = 0) Global
  return JDB.solveInt(_Path(aKey), default)
EndFunction
