-- LDoc configuration file
title = "ILuaJIT"
description = "Readline powered shell for LuaJIT"
format = "markdown"

-- Automatic module field detection does not support nested tables.
new_type("setting", "Settings")

readme = "README.md"
file = {
  "shell.lua",
  "completer.lua"
}
