-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

--#include "src/libluacomp.lua"

__DSYM = {}

local parser = argparse(arg[0]:match("[^/]+$"), "LuaComp v"..LUACOMP_VERSION.."\nA preprocessor+postprocessor written in Lua.")
parser:argument("input", "Input file (- for STDIN)")
parser:option("-O --output", "Output file. (- for STDOUT)", "-")
parser:option("-m --minifier", "Sets the postprocessor", "none")
parser:option("-x --executable", "Makes the script an executable (default: current lua version)"):args "?"
parser:flag("-g --debugging", "Adds inline debugging utils to assist in debugging."):action(function() DEBUGGING=true end)
parser:flag("--generator-code", "Outputs only the code from the generator.")
parser:flag("--verbose", "Verbose output. (Debugging)"):action(function() VERBOSE=true end)
parser:flag("--post-processors", "Lists postprocessors"):action(function()
	preload_providers()
	local provs = {}
	for k, v in pairs(providers) do
		provs[#provs+1] = k
	end
	table.sort(provs)
	print(table.concat(provs, "\n"))
	os.exit(0)
end)
parser:flag("--directives", "Lists directives"):action(function()
	preload_directives()
	local dirs = {}
	for k, v in pairs(directives) do
		dirs[#dirs+1] = k
	end
	table.sort(dirs)
	print(table.concat(dirs, "\n"))
	os.exit(0)
end)
parser:flag("-v --version", "Prints the version and exits"):action(function()
	print(LUACOMP_VERSION)
	os.exit(0)
end)
parser:add_complete()
local args = parser:parse()
local file = args.input
_sv("LUACOMP_MINIFIER", args.minifier)
local f
if (file ~= "-") then
	local sr, er = stat.stat(file)
	if not sr then lc_error("luacomp", er) end
	f = io.open(file, "r")
else
	f = io.stdin
end
local ocode = luacomp.process_file(f, (file == "-") and "stdin" or file, args.generator_code)
if DEBUGGING then
	-- generate debugging symbols
	local dsyms = {"LEM:LCDEBUG!!!"}
	for i=1, #__DSYM do
		local sym = __DSYM[i]
		local sym_str = string.format("FILE[%s]:START[%d,%d]:END[%d:%d]:FILE[%d,%d]", sym.file, sym.sx or 0, sym.sy or 0, sym.ex or 0, sym.ey or 0, sym.fx or -1, sym.fy or -1)
		if sym.tag then
			sym_str = sym_str .. ":"..sym.tag
		end
		table.insert(dsyms, sym_str)
	end
	ocode = ocode .. "\n--[["..table.concat(dsyms, "\n").."\n]]"
end

if DEBUGGING then
	local dsymt = {}
	for i=1, #__DSYM do
		local sym = __DSYM[i]
		local symstr = string.format("file=%q,sx=%q,sy=%q,ex=%q,ey=%q,fx=%q,fy=%q", sym.file, sym.sx or 0, sym.sy or 0, sym.ex or 0, sym.ey or 0, sym.fx or -1, sym.fy or -1)
		if sym.tagv then
			for i=1, #sym.tagv.vals do
				sym.tagv.vals[i]=string.format("%q", sym.tagv.vals[i])
			end
			symstr = symstr .. ",tag={" ..string.format("type=%q,vals={%s}", sym.tagv.type, table.concat(sym.tagv.vals, ",")).."}"
		end
		table.insert(dsymt,"{"..symstr.."}")
	end
	ocode = "_G['LCDEBUG!!!'] = {\n"..table.concat(dsymt, ",\n").."\n}\n" .. ocode
end

local minifier = providers[args.minifier]
dprint("Minifier: "..args.minifier, minifier)
if not minifier then
	lc_error("luacomp", "Postprocessor "..args.minifier.." not found!")
	--io.stderr:write("ERROR: Postprocessor `"..args.minifier.."' not found!\n")
	--os.exit(1)
end
dprint("Running...")
local rcode, err = minifier(ocode)

if (not rcode) then
	--io.stderr:write("ERROR: Error for postprocessor `"..args.minifier.."': \n")
	--io.stderr:write(err)
	--os.exit(1)
	lc_error(args.minifier, "Postprocessor error:\n"..err)
end

local of
if (args.output == "-") then
	of = io.stdout
else
	of = io.open(args.output, "w")
end
local ver = _VERSION:lower():gsub(" ", "")
if jit then
	ver = "luajit"
end
if (args.executable) then
	of:write("#!/usr/bin/env ", args.executable[1] or ver, "\n")
end
of:write(rcode)
of:close()
--f:close()