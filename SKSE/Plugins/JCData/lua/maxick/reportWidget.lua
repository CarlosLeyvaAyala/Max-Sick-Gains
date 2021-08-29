local l = jrequire 'dmlib'
local gc = jrequire 'maxick.genConst'
local db = jrequire 'maxick.database'
-- local serpent = require('__serpent')

---@alias Meters table
---@alias Meter table<string, number>
---@alias Widget table

local reportWidget = {}

-- ;>========================================================
-- ;>===                   CONSTANTS                    ===<;
-- ;>========================================================

---@alias HAlign
---|'1' "left"
---|'2' "center"
---|'3' "right"

---@alias VAlign
---|'1' "top"
---|'2' "center"
---|'3' "bottom"

---@type HAlign
local HAlign = gc.HAlign
local VAlign = gc.VAlign


--- Hardcoded value for the screen size the `"\interface\exported\widgets\...\meter.swf"` flash file uses for positioning a meter.
local screenX = 1280
--- Hardcoded value for the screen size the `"\interface\exported\widgets\...\meter.swf"` flash file uses for positioning a meter.
local screenY = 720


-- ;>========================================================
-- ;>===               METER POSITIONING                ===<;
-- ;>========================================================

--#region Helpers for setting Y position

---Gets the vertical dimensions of the whole widget.
---@param numMeters integer Number of meters in the widget.
---@param meterH number Height for each meter.
---@param vGap number Vertical gap between meters.
---@return number fullMeterH Height for each meter in the widget. Gaps included.
---@return number fullWidgetH Height for the whole widget.
local function _DefineWholeWidgetDimensions(numMeters, meterH, vGap)
  local fullMeterH = meterH + (meterH * vGap)
  local fullWidgetH = (fullMeterH * (numMeters - 1)) + meterH
  return fullMeterH, fullWidgetH
end

---Gets the actual Y position of the whole widget on screen.
---
---This function makes displacements to take into account how vertical anchors in `"\interface\exported\widgets\...\meter.swf"` change depending on alignment.
---@param vAlign integer
---@return number
local function _WidgetScreenY(vAlign, meterH, fullWidgetH)
  if vAlign ~= VAlign.top then
    local displace = screenY + (meterH - fullWidgetH)
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
---@param vAlign VAlign Vertical alignment of the whole widget.
---@param meterH number Individual meter height.
---@param fullMeterH number Height for each meter in the widget. Gaps included.
---@param fullWidgetH number Height for the whole widget.
---@return Meter meter Individual meter data.
local function _SetMeterY(meter, relPos, dY, vAlign, meterH, fullMeterH, fullWidgetH)
  meter.y = _WidgetScreenY(vAlign, meterH, fullWidgetH) + (relPos * fullMeterH) + dY
  return meter
end

-- ;>========================================================
-- ;>===                     SETUP                      ===<;
-- ;>========================================================

-- ---Creates a table from an array of numbers (usually generated with `range`).
-- ---@param array table<integer, integer> Array of numbers to transform.
-- ---@param indexGen fun(index:integer, value: integer): any Index transformation function.
-- ---@param valGen fun(val: integer, key: any): any Value transformation function.
-- local function tableFromNumbers(array, indexGen, valGen)
--   return l.pipe(indexGen, valGen)(array)
-- end

-- ---Appends a value to a string.
-- ---@param str string
-- ---@return fun(val: any): string
-- local function appendStr(str) return function (val) return str..tostring(val) end end

---Creates the table skeleton for all the meters in the widget.
---@return table<string, Meter>
local function _CreateMeters()
  return l.tableFromNumbers(
    l.range(3),
    l.buildKeys(l.appendStr("meter")),
    l.map(function (v) return {x = 0, y = 0, n = v } end)
  )
end

---Calculates the screen position of each meter based on settings.
---@param x number
---@param y number
---@param meterH number
---@param vGap number
---@param hAlign HAlign
---@param vAlign VAlign
---@return table<string, Meter>
function reportWidget.MeterPositions(x, y, meterH, vGap, hAlign, vAlign)
  local meters = _CreateMeters()
  local fullMeterH, fullWidgetH = _DefineWholeWidgetDimensions(l.tableLen(meters), meterH, vGap)
  return l.pipe(
    l.map(function (v) return _SetMeterX(v, x, hAlign) end),
    l.map(function (v) return _SetMeterY(v, v.n - 1, y, vAlign, meterH, fullMeterH, fullWidgetH) end)
  )(meters)
end

-- print(serpent.block(reportWidget.MeterPositions(0,0, 17.5, -0.15, HAlign.right, VAlign.center)))

return reportWidget
