-- Very simple binding for Readline in Lua (using FFI callbacks)
-- This is meant to be simple, not complete.

local ffi = require"ffi"
local assert = assert
local cocreate, coresume, costatus = coroutine.create, coroutine.resume, coroutine.status
local M = { }

ffi.cdef[[
  /* libc definitions */
  void* malloc(size_t bytes);
  void free(void *);
  
  /* basic history handling */
  char *readline (const char *prompt);
  void add_history(const char *line);
  
  /* completion */
  typedef char **rl_completion_func_t (const char *, int, int);
  typedef char *rl_compentry_func_t (const char *, int);
  
  char **rl_completion_matches (const char *, rl_compentry_func_t *);
  
  const char *rl_basic_word_break_characters;
  rl_completion_func_t *rl_attempted_completion_function;
  char *rl_line_buffer;
  int rl_completion_append_character;
  int rl_attempted_completion_over;
]]

local libreadline = ffi.load("readline")

function M.completion_append_character(char)
  libreadline.rl_completion_append_character = #char > 0 and char:byte(1,1) or 0
end

function M.shell(config)
  -- configure completion, if any
  if config.complete then
    if config.word_break_characters then
      libreadline.rl_basic_word_break_characters = config.word_break_characters
    end
    
    function libreadline.rl_attempted_completion_function(word, startpos, endpos)
      local strword = ffi.string(word)
      local buffer = ffi.string(libreadline.rl_line_buffer)
      local matches = config.complete(strword, buffer, startpos, endpos)
      if not matches then return nil end
      -- if matches is an empty array, tell readline to not call default completion (file)
      libreadline.rl_attempted_completion_over = 1
      -- translate matches table to C strings 
      -- (there is probably more efficient ways to do it)
      return libreadline.rl_completion_matches(word, function(text, i)
        local match = matches[i+1]
        if match then
          -- readline will free the C string by itself, so create copies of them
          local buf = ffi.C.malloc(#match + 1)
          ffi.copy(buf, match, #match+1)
          return buf
        else
          return ffi.new("void*", nil)
        end
      end)
    end
  end
  
  -- main loop
  local running = true
  while running do
    local userfunc = cocreate(config.getcommand)
    local _, prompt = assert(coresume(userfunc))
    while costatus(userfunc) ~= "dead" do
      -- get next line
      local s = libreadline.readline(prompt)
      if s == nil then  -- end of file
        running = false
        break
      end
      
      local line = ffi.string(s)
      ffi.C.free(s)
      _, prompt = assert(coresume(userfunc, line))
    end
    
    if prompt then -- final return value is the value to add to history
      libreadline.add_history(prompt)
    end
  end
end

return M
