-- Quick dirty script to make necessary substitutions before developing/releasing

local function processFile(ff, processing)
  --  Read the file
  local ft = io.open(ff, "r")
  local content = ft:read("*all")
  ft:close()

  -- Edit the string
  content = processing(content)
--  print(content)

  -- Write it out
  ft = io.open(ff, "w")
  ft:write(content)
  ft:close()
end

local requireMod = string.format("require '%s.", arg[3])

-- Reverts back libraries that need to stay as is
local function revertLibRequire(content, libName)
  return string.gsub(content, requireMod.. libName .."'", "require '" .. libName .. "'")
end

local function makeRelease(content)
  content = string.gsub(content, "package.path = ", "-- package.path = ")
  content = string.gsub(content, " = require ", " = jrequire ")
  content = string.gsub(content, "require '", requireMod)

  -- ;TODO: Modify these
  content = revertLibRequire(content, "jc")
  content = revertLibRequire(content, "dmlib")
  return content
end

local function makeDebug(content)
  content = string.gsub(content, "-- package.path = ", "package.path = ")
  content = string.gsub(content, " = jrequire ", " = require ")
  content = string.gsub(content, requireMod, "require '")
  return content
end

if(arg[1] == "r") then
  print("changing for releasing", arg[2])
  processFile(arg[2], makeRelease)
elseif(arg[1] == "d") then
  print("changing for debugging", arg[2])
  processFile(arg[2], makeDebug)
end
