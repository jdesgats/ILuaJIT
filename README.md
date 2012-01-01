ILuaJIT - Readline powered shell for LuaJIT
===========================================

## Introduction

**This project is just at early stages of it's development.**
It's nowhere near finished or stable or anything !

This script provides a shell with readline integration to LuaJIT. It uses a 
adapted version [lua-rlcompleter](https://github.com/rrthomas/lua-rlcompleter) 
for completion engine and a pure Lua binding for readline (thanks to LuaJIT FFI).

It is also intended to ease interaction with Lua a bit like IPython for Python
with features such as:

  * History (not persistant yet)
  * Improved error handling: shows the code which caused error
  * Pretty printed output: terminal colors, print tables, ...
  * Anything else you could imagine ! (any contribution is welcome)

Complete HTML documentation is available online [here](http://jdesgats.github.com/ILuaJIT).


## Installation

ILuaJIT has not been tested on a lot of systems but should work on any Readline
capable system.

You need at least the following dependencies installed :

  * [LuaJIT 2.0 beta 9](http://luajit.org/download.html)
  * [Penlight](https://github.com/stevedonovan/Penlight) in your `LUA_PATH`
  * libreadline

Optionnally, if [lfs](http://keplerproject.github.com/luafilesystem) is installed,
it will be used to complete file names inside strings.

Once eveything is set up, just clone the repo or unpack an 
[archive](https://github.com/jdesgats/ILuaJIT/zipball/master) somewhere.

[HTML documentation](http://jdesgats.github.com/ILuaJIT) is done using
[LDoc](https://github.com/stevedonovan/LDoc). As a config file is provided, all
you have to do to build it is to invoke LDoc in ILuaJIT directory.

## Usage

To run the shell, start just `iluajit.lua` :

    luajit iluajit.lua

An extra global variable `shell` is available to customize nearly any aspect of
the shell. To see available options, see `shell` module documentation.

## Known issues

 * `undefined symbol: PC` error on startup: it's a dependency problem when
   loading libreadline, try to preload libtermcap (with something like 
   `LD_PRELOAD=/usr/lib/libtermcap.so luajit iluajit.lua`).
   See [this post](http://lua-users.org/lists/lua-l/2011-12/msg00705.html).

## License (MIT)

Copyright (C) 2011-2012 Julien Desgats

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
