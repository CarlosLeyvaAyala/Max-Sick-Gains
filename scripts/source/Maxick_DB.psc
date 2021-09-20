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

; Saves a string.
Function SaveStr(string aKey, string aValue) Global
  JDB.solveStrSetter(_Path(aKey), aValue, true)
EndFunction

; Gets a string. Returns `default` if key was not found.
string Function GetStr(string aKey, string default = "") Global
  return JDB.solveStr(_Path(aKey), default)
EndFunction

; Saves a JContainers object.
Function SaveObj(string aKey, int aHandle) Global
  JDB.solveObjSetter(_Path(aKey), aHandle, true)
EndFunction

; Gets a JContainers object handle. Returns `default` if key was not found.
int Function GetObj(string aKey, int default = 0) Global
  return JDB.solveObj(_Path(aKey), default)
EndFunction

; Saves a form.
Function SaveForm(string aKey, Form aValue) Global
  JDB.solveFormSetter(_Path(aKey), aValue, true)
EndFunction

; Gets a form. Returns `default` if key was not found.
Form Function GetForm(string aKey, Form default = None) Global
  return JDB.solveForm(_Path(aKey), default)
EndFunction

; Asociates a JContainers object to some form.
Function FormSaveObj(Form fKey, string aPath, int aHandle) Global
  JFormDB.solveObjSetter(fKey, _Path(aPath), aHandle, true)
EndFunction

; Gets a JContainers object handle. Returns `default` if form key or path were not found.
int Function FormGetObj(Form fKey, string aPath, int default = 0) Global
  return JFormDB.solveObj(fKey, _Path(aPath), default)
EndFunction

; Returns a valid ActorBase that can be used for memoization.
ActorBase Function MemoActor(Actor aAct) Global
  return aAct.GetActorBase()
EndFunction

; Saves an actor's calculated appearance to memory database.
Function MemoizeAppearance(Actor aAct, int appearance) Global
  Maxick_DB.FormSaveObj(Maxick_DB.MemoActor(aAct), "memoized", appearance)
EndFunction

; Gets an actor's calculated appearance from memory database.
int Function GetMemoizedAppearance(Actor aAct) Global
  return Maxick_DB.FormGetObj(Maxick_DB.MemoActor(aAct), "memoized")
EndFunction
