-- Internal logic and configuration

local completer = require "completer"
local stringio = require "pl.stringio"
local pretty = require "pl.pretty"

--- Adds VT100 control codes to colorize text anr resets settings.
-- Result is `<ESC>[...m<text><ESC>[0m`
local function colorize(text, ...)
  local codes = { }
  for i, code in ipairs{...} do codes[i] = tostring(code) end
  return "\027[" .. table.concat(codes, ";") .. "m" .. text .. "\027[0m"
end

--- Highlights a line in a file.
-- Prints given line and some sorrounding lines in a file. The target line is highlighted.
local function highlight_line(file, target, area)
  local tmpl   = "    %04d: %s"
  local buffer = { }
  local lineno = 1
  for line in file:lines() do
    if lineno > target+area then break -- area to display is passed
    elseif lineno == target then
      buffer[#buffer+1] = tmpl:format(lineno, colorize(line, 31))
    elseif lineno >= target - area then
      buffer[#buffer+1] = tmpl:format(lineno, line)
    end
    lineno = lineno + 1
  end
  return table.concat(buffer, "\n")
end

-- This global variable will contain some settings that can be user-changed
local shell = { }
shell._VERSION = "0.1"
shell._COPYRIGHT = "(c) 2011 Julien Desgats, with contributions from Patrick Rapin and Reuben Thomas"
shell._LICENSE = "MIT License"
if jit then
  shell.greetings = ("ILuaJIT %s, running %s\nJIT:%s %s\n"):format(shell._VERSION, jit.version,
    jit.status() and "ON" or "OFF", table.concat({ select(2, jit.status()) }, " "))
else
  shell.greetings = ("ILuaJIT %s, running %s\n"):format(shell._VERSION, _VERSION)
end

shell.value = { } -- Result value options
shell.value.separator = "\n"
shell.value.prettyprint_tables = true
shell.value.table_use_tostring = true -- when false, pretty print tables even if a __tostring method exists.

shell.onerror = { }
shell.onerror.print_code = true  -- if true, error handler will try to print source code where error happend
shell.onerror.area = 3           -- number of lines before and after the problematic line to print

shell.prompt = function(primary) return primary and ">  " or ">> " end
shell.completer = completer
shell.input_sequence = 1 -- incremented for each new command (used to generate chunk names)


-- Some callbacks to affect display, they should *not* print anything but return
-- strings, it is intended to ease some complex configurations (remote, ...)

-- Responsible to transform result into a printable string
-- Called with the result position and values (starting from pos)
function shell.value.handler(pos, value)
  local tvalue = type(value)
  if tvalue == "table" and shell.value.prettyprint_tables then
    -- if table has a __tostring metamethod, then use it
    local mt = getmetatable(value)
    if mt and mt.__tostring and shell.value.table_use_tostring then
      value = tostring(value)
    else
      -- otherwise pretty-print it
      -- TODO: make a custom pretty print function: short tables on a single line,
      -- clearer indentation, ...
      value = pretty.write(value)
    end
  else -- fall back to default tostring
    value = tostring(value)
  end
  return colorize("["..pos.."]", 1, 30) .. " "..value
end

-- mapping between typed commands (as function reference) and corresponding source
local src_history = setmetatable({ }, { __mode = "k" })

-- Called by xpcall when something goes wrong. Must return the string to be printed.
function shell.onerror.handler(err)
  local buffer = { colorize(tostring(err), 31), "Stack traceback:" }
  local tmpl   = "  At %s:%d (in %s %s)"
  for i=2, math.huge do
    local info = debug.getinfo(i)
    if not info then break end
    buffer[#buffer+1] = tmpl:format(info.source, info.currentline or -1, info.namewhat, info.name or "?")
    if shell.onerror.print_code and (info.what == "Lua" or info.what == "main") and info.currentline then
      local file
      if src_history[info.func]       then file = stringio.open(src_history[info.func])
      elseif info.source:match("^@")  then file = io.open(info.source:sub(2), "r") end
      if file then
        buffer[#buffer+1] = highlight_line(file, info.currentline, shell.onerror.area)
      end
    end
  end
  return table.concat(buffer, "\n")
end

-- prints argument only if there is at least one
function shell.result_handler(success, ...)
  if success then
    local buf = { }
    for i=1, select("#", ...) do
      buf[i] = shell.value.handler(i, select(i, ...))
    end
    return table.concat(buf, shell.value.separator)
  end
  -- error
  return (...)
end

function shell.try(cmd)
  local chunkname = "stdin#"..shell.input_sequence
  local func = assert(loadstring(cmd, chunkname))
  shell.input_sequence = shell.input_sequence + 1
  src_history[func] = cmd
  return shell.result_handler(xpcall(func, shell.onerror.handler))
end

return shell
