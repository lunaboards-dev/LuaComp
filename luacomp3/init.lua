--@[[if false then]]
local parser = require("luacomp3.parser")
--@[[else]]
--#include "parser.lua" "parser"
--@[[end]]

local p = setmetatable({}, {__index=parser})
p:init()
local f = io.open(arg[1], "rb")
local d = f:read("a")
f:close()
p:parse(d)