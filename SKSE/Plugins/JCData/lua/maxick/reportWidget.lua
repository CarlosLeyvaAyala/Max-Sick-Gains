local l = jrequire 'dmlib'
local gc = jrequire 'maxick.genConst'
local db = jrequire 'maxick.database'
-- local serpent = require('__serpent')

---@alias Meters table
---@alias Meter table
---@alias Widget table

local reportWidget = {}

-- local function _GenWidgetJson(widget)
--   local luna = jrequire 'maxick.lunajson'
--   local dataTree = luna.encode(widget)
--   print(dataTree)
--   local ft = io.open("../../../Maxick/widget.json", "w+")
--   io.output(ft)
--   io.write(dataTree)
--   io.close()
-- end

-- ;>========================================================
-- ;>===                   CONSTANTS                    ===<;
-- ;>========================================================

local HAlign = gc.HAlign
local VAlign = gc.VAlign

--- Use this for reference on what Papyrus should send here.
local sampleWidget = {
  --#region Values coming from database.

  --- Delta x for the whole widget
  x = 40,
  --- Delta Y for the whole widget
  y = 40,
  meterH = 10,
  meterW = 15,
  vGap = 0,
  vAlign = VAlign.top,
  hAlign = HAlign.left,
  hA = "left",
  vA = "top",
  --- This used to be the value for the rate of refresh, and it was tied
  --- with the rate at which polling calculations were done (quite a bad
  --- design on my part), but was left here just for compatibility, albeit
  --- not being used anymore.
  widgetRefresh = 60,
  --#endregion

  --#region Values actually calculated by this script:

  meters = {
    meter1 = { x = 0, y = 0, color = 0, n = 1, },
    meter2 = { x = 0, y = 0, color = 0, n = 2, },
    meter3 = { x = 0, y = 0, color = 0, n = 3, },
  },
  flashColors =   {
    normal = 0, warning = 0, danger = 0, critical = 0, down = 0, up = 0,
  },
  --#endregion
}

--- Colors are assigned here and not in Papyrus because their values get baked into game saves in there.
--- Dynamically changing them is a pain in the ass.
local meterColors = {
  0xc0c0c0,    -- Silver. Gains meter.
  0x6b17cc,    -- Violet. Training meter.
  0xf2e988,    -- Yellow. Inactivity meter.
  -- 0xa6c942,    -- Green (used in Sandow Plus Plus, not here; but left in case it will be used in the future)
}

--- Colors are assigned here and not in Papyrus because their values get baked into game saves in there.
--- Dynamically changing them is a pain in the ass.
local flashColors = {
  normal = 0xffffff,    -- White
  warning = 0xffd966,   -- Gold
  danger = 0xff6d01,    -- Orange
  critical = 0xff0000,  -- Red
  down = 0xcc0000,      -- Darker red
  up = 0x4f8a35,        -- Green
}

--- Hardcoded value for the screen size the `"\interface\exported\widgets\...\meter.swf"` flash file uses for positioning a meter.
local screenX = 1280
--- Hardcoded value for the screen size the `"\interface\exported\widgets\...\meter.swf"` flash file uses for positioning a meter.
local screenY = 720


-- ;>========================================================
-- ;>===               METER POSITIONING                ===<;
-- ;>========================================================

--#region Helpers for setting Y position

---The height of a meter.
local _meterH = 0

---The height of a meter; vertical gap included.
local _fullMeterH = 0

---The height for the whole widget.
local _fullWidgetH = 0

local function _DefineWholeWidgetDimensions(widget)
  _meterH = widget.meterH
  _fullMeterH = _meterH + (_meterH * widget.vGap)
  _fullWidgetH = (_fullMeterH * (l.tableLen(widget.meters) - 1)) + _meterH
end

---Gets the actual Y position of the whole widget on screen.
---
---This function makes displacements to take into account how vertical anchors in `"\interface\exported\widgets\...\meter.swf"` change depending on alignment.
---@param vAlign integer
---@return number
local function _WidgetScreenY(vAlign)
  if vAlign ~= VAlign.top then
    local displace = screenY + (_meterH - _fullWidgetH)
    if vAlign == VAlign.center then displace = displace / 2 end
    return displace
  end
  return 0
end
--#endregion

---Sets a meter X position based on the widget settings.
---@param meter Meter Meter data.
---@param dX number Delta X to displace the whole widget.
---@param hAlign integer Horizontal alignment of the whole widget.
---@return Meter
local function _SetMeterX(meter, dX, hAlign)
  ---Returns the actual X position of the widget on screen.
  ---@return number
  local function _WidgetScreenX()
    if hAlign == HAlign.center then return screenX / 2
    elseif hAlign == HAlign.right then return screenX
    else return 0
    end
  end
  meter.x = _WidgetScreenX() + dX
  return meter
end

---Sets a meter Y position based on the widget settings.
---@param meter Meter Meter data.
---@param relPos integer Relative position of this particular meter on the stack.
---@param dY number Delta Y to displace the whole widget.
---@param vAlign integer Vertical alignment of the whole widget.
---@return Meter
local function _SetMeterY(meter, relPos, dY, vAlign)
  meter.y = _WidgetScreenY(vAlign) + (relPos * _fullMeterH) + dY
  return meter
end

---Sets `x` and `y` positions for all meters.
---@param widget Widget
---@return fun(meters: Meters): Meters
local function _SetMeterPositions(widget)
  return function (meters)
    return l.pipe(
      l.map(function (v) return _SetMeterX(v, widget.x, widget.hAlign) end),
      l.map(function (v) return _SetMeterY(v, v.n - 1, widget.y, widget.vAlign) end)
    )(meters)
  end
end


-- ;>========================================================
-- ;>===                     SETUP                      ===<;
-- ;>========================================================

---Changes only the meters in the widget.
---@param func fun(meters: Meters): Meters Function that alters only the meters on a widget.
---@return fun(widget: Widget): Widget
local function _ChangeMeters(func)
  return function (widget)
    l.assign(widget.meters, func(widget.meters))
    return widget
  end
end

---Assigns its corresponding color to each meter.
---@param meters Meters
---@return Meters
local function _SetColors(meters)
  return l.map(meters, function (v)
    v.color = meterColors[v.n]
    return v
  end)
end

---Sets the values for the color flashes.
---@param widget Widget
---@return Widget
local function _SetFlashColors(widget)
  l.assign(widget.flashColors, l.map(widget.flashColors, function (_, k)
    return flashColors[k]
  end))
  return widget
end

---Sets the position for all meters in the widget.
---@param widget Widget
---@return Widget
local function _SetPosition(widget)
  return _ChangeMeters(_SetMeterPositions(widget))(widget)
end

---Initializes data generated by _Max Sick Gains.exe_.
---@param widget Widget
---@return Widget
local function _InitFromDB(widget)
  widget.x = db.mcm.widgetX
  widget.y = db.mcm.widgetY
  widget.widgetRefresh = db.mcm.widgetRefresh
  widget.meterH = db.mcm.widgetMH
  widget.meterW = db.mcm.widgetMW
  widget.vGap = db.mcm.widgetMGap
  widget.vAlign = db.mcm.widgetVAlign
  widget.hAlign = db.mcm.widgetHAlign
  widget.hA = HAlign[widget.hAlign]
  widget.vA = VAlign[widget.vAlign]
  return widget
end

---Sets the initial data for a widget.
---@param widget Widget
---@return Widget
function reportWidget.Init(widget)
  return l.processTable(widget, {
    _InitFromDB,
    l.tap(_DefineWholeWidgetDimensions),
    _ChangeMeters(_SetColors),
    _SetPosition,
    _SetFlashColors,
  })
end

-- print(serpent.block(reportWidget.Init(sampleWidget)))
-- _GenWidgetJson(reportWidget.Init(sampleWidget))

return reportWidget
