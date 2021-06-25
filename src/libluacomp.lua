-- A LuaComp library
local luacomp = {}

local directives = {}

local unistd = require("posix.unistd")

local function lc_error(name, msg)
	if unistd.isatty(2) then
		io.stderr:write(string.format("\27[90;1m(%s) \27[31;22m%s\27[0m\n", name, msg))
	else
		io.stderr:write(string.format("(%s) %s\n", name, msg))
	end
	os.exit(1)
end

local function lc_warning(name, msg)
	if unistd.isatty(2) then
		io.stderr:write(string.format("\27[90;1m(%s) \27[33;22m%s\27[0m\n", name, msg))
	else
		io.stderr:write(string.format("(%s) %s\n", name, msg))
	end
end

function luacomp.error(msg)
	local inf = debug.getinfo(1)
	local name = (inf and inf.short_src:match("[^/]+$"):gsub("^[=@]", "")) or "luacomp"
	lc_error(name, msg)
end

function luacomp.warning(msg)
	local inf = debug.getinfo(1)
	local name = (inf and inf.short_src:match("[^/]+$"):gsub("^[=@]", "")) or "luacomp"
	lc_warning(name, msg)
end

--#include "src/ast2.lua"
--#include "src/generator2.lua"

function luacomp.process_file(file, fname, dry)
	io.stderr:write("PROC\t", fname, "\n")
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