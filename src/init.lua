--[[
	init.lua - Main file of LuaComp

   Copyright 2019 Adorable-Catgirl

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]

--#include "luacomp_vars.lua"
--#include "ast.lua"
--#include "generator.lua"
--#include "directive_provider.lua"
--#include "cfg/minifier_providers.lua"

local argparse = require("argparse")

local parser = argparse(arg[0], "LuaComp v"..LUACOMP_VERSION.."\nA Lua preprocessor+postprocessor.")
parser:argument("input", "Input file (- for STDIN)")
parser:option("-O --output", "Output file. (- for STDOUT)", "-")
parser:option("-m --minifier", "Sets the minifier", "none")
parser:flag("-x --executable", "Makes the script an executable")
local args = parser:parse()
local file = args.input
local f
if (file ~= "-") then
	if (not os.execute("stat "..file..">/dev/null")) then
		io.stderr:write("ERROR: File `"..file.."' does not exist!\n")
		os.exit(1)
	end
	f = io.open(file, "r")
else
	file = io.stdin
end
local ast = mkast(f, file)
local ocode = generate(ast)

local minifier = providers[args.minifier]

local rcode = minifier(ocode)

local of
if (args.output == "-") then
	of = io.stdout
else
	of = io.open(args.output, "w")
end
if (args.executable) then
	of:write("#!/usr/bin/env lua5.3\n")
end
of:write(rcode)
of:close()
f:close()
