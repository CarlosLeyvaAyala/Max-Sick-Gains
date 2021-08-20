--- Shared functions that only make sense for this mod
local lib = {}

local l = jrequire 'dmlib'

lib.loggingLvl = l.enum({"None", "Critical", "Info", "Verbose"})

return lib
