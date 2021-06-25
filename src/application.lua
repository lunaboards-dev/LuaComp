local function dprint(...)
	local args = {...}
	for i=1, #args do
		args[i] = tostring(args[i])
	end
	if (false) then
		io.stderr:write("DEBUG\t"..table.concat(args,"\t"),"\n")
	end
end

--#include "src/shell_var.lua"
--#include "src/luacomp_vars.lua"
--#include "src/libluacomp.lua"
--#include "src/directive_provider.lua"
--#include "src/cfg/minifier_providers.lua"

local parser = argparse(arg[0]:match("[^/]+$"), "LuaComp v"..LUACOMP_VERSION.."\nA preprocessor+postprocessor written in Lua.")
parser:argument("input", "Input file (- for STDIN)")
parser:option("-O --output", "Output file. (- for STDOUT)", "-")
parser:option("-m --minifier", "Sets the postprocessor", "none")
parser:option("-x --executable", "Makes the script an executable (default: current lua version)"):args "?"
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
	f = io.open(file, "r")
	if not f then
		io.stderr:write("ERROR: File `"..file.."' does not exist!\n")
		os.exit(1)
	end
else
	f = io.stdin
end
local ocode = luacomp.process_file(f, (file == "-") and "stdin" or file, args.generator_code)

local minifier = providers[args.minifier]
dprint("Minifier: "..args.minifier, minifier)
if not minifier then
	io.stderr:write("ERROR: Postprocessor `"..args.minifier.."' not found!\n")
	os.exit(1)
end
dprint("Running...")
local rcode, err = minifier(ocode)

if (not rcode) then
	io.stderr:write("ERROR: Error for postprocessor `"..args.minifier.."': \n")
	io.stderr:write(err)
	os.exit(1)
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