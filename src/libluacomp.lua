-- A LuaComp library
local luacomp = {}

local directives = {}

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