-- A LuaComp library
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local function dprint(...)
	local args = {...}
	for i=1, #args do
		args[i] = tostring(args[i])
	end
	if (false) then
		io.stderr:write("DEBUG\t"..table.concat(args,"\t"),"\n")
	end
end

local stat = require("posix.sys.stat")
local dirent = require("posix.dirent")
local unistd = require("posix.unistd")

local function lc_error(name, msg)
	if unistd.isatty(2) then
		io.stderr:write(string.format("\27[90;1m(%s) \27[31merror: \27[22m%s\27[0m\n", name, msg))
	else
		io.stderr:write(string.format("(%s) %s\n", name, msg))
	end
	os.exit(1)
end

local function lc_warning(name, msg)
	if unistd.isatty(2) then
		io.stderr:write(string.format("\27[90;1m(%s) \27[33mwarning: \27[22m%s\27[0m\n", name, msg))
	else
		io.stderr:write(string.format("(%s) %s\n", name, msg))
	end
end

local luacomp = {}
local directives = {}

--#include "src/shell_var.lua"
--#include "src/luacomp_vars.lua"
--#include "src/directive_provider.lua"
--#include "src/cfg/minifier_providers.lua"

@[[if not svar.get("LIBLUACOMP") then]]
_G.luacomp = luacomp
@[[end]]

function luacomp.error(msg)
	local inf = debug.getinfo(2)
	local name = (inf and inf.short_src:match("[^/]+$"):gsub("^[=@]", "")) or "luacomp"
	lc_error(name, msg)
end

function luacomp.warning(msg)
	local inf = debug.getinfo(2)
	local name = (inf and inf.short_src:match("[^/]+$"):gsub("^[=@]", "")) or "luacomp"
	lc_warning(name, msg)
end

--#include "src/ast2.lua"
--#include "src/generator2.lua"

function luacomp.process_file(file, fname, dry)
	@[[if not svar.get("LIBLUACOMP") then]]
	io.stderr:write("PROC\t", fname, "\n")
	@[[end]]
	if type(file) == "string" then
		file = io.open(file, "r")
	end
	local d = file:read("*a"):gsub("\r\n", "\n"):gsub("\r", "\n")
	file:close()
	return luacomp.process_string(d, fname or file, dry)
end

function luacomp.process_string(str, name, dry)
	local str = ast.str_to_stream(str, name)
	local cast = ast.parse(str)
	local gcode = generator.parse_ast(name, cast)
	if dry then
		return gcode
	end
	--error("TODO: implement generation")
	return generator.run_gcode(name, gcode)
end

function luacomp.run_minifier(minifier, code)
	local min = providers[minifier]
	if not minifier then
		lc_error("luacomp", "Postprocessor "..minifier.." not found!")
		--io.stderr:write("ERROR: Postprocessor `"..args.minifier.."' not found!\n")
		--os.exit(1)
	end
	local rcode, err = min(code)
	if (not rcode) then
		lc_error(args.minifier, "Postprocessor error:\n"..err)
	end
	return rcode
end

@[[if svar.get("LIBLUACOMP") then]]
return luacomp
@[[end]]