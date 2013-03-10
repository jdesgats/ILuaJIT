--- ILuaNG: improved interactive shell for Lua JIT
-- This little program mainly brings Readline autocompletion (thanks to FFI callbacks)
-- and some others improvements to regular LuaJIT shell.
--
-- TODO list (just a bunch of ideas, some could be useful, others are completely crazy):
--     * Interface with other Lua implementations (e.g. Lua 5.2 through FFI)
--     * Smarter completion (e.g. module listing on require)
--     * Real time syntax highlight ?
--     * Allow to customize preprocessors (like transforming "=" to "return")

local readline = require "readline"
local coyield = coroutine.yield

shell = require "shell"

shell.completer.final_char_setter = readline.completion_append_character

io.stdout:write(shell.greetings)
readline.shell{
  getcommand = function()
    local func, err
    -- get the first line and resolve the "=" shortcut
    local cmd = coyield(shell.prompt(true)) .. "\n"
    if cmd:sub(1,1) == "=" then
      cmd = "return "..cmd:sub(2)
    end

    -- continue to get lines until get a complete chunk
    while true do
      func, err = loadstring(cmd)
      if func or err:sub(-7) ~= "'<eof>'" then break end
      cmd = cmd .. coyield(shell.prompt(false)) .. "\n"
    end

    if not cmd:match("^%s*$") then
      local output
      if func then
        output = shell.try(cmd)
      else output = err end

      -- display the result
      io.stdout:write(output, #output > 0 and output:sub(-1, -1) ~= "\n" and "\n" or "")
      return cmd:sub(1, -2) -- remove last \n for history
    end
  end,

  complete = shell.completer.complete,
  word_break_characters = " \t\n\"\\'><=;:+-*/%^~#{}()[].,",
}

io.stderr:write"\n" -- avoid to concatenate iLua and sh prompts at exit
