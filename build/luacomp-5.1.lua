#!/usr/bin/env lua5.1
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


local function _sv(k, v)
	_G[k] = v
	--os.setenv(k, tostring(v))
end

_sv("LUACOMP_V_MAJ", 1)
_sv("LUACOMP_V_MIN", 1)
_sv("LUACOMP_V_PAT", 0)
_sv("LUACOMP_VERSION", LUACOMP_V_MAJ.."."..LUACOMP_V_MIN.."."..LUACOMP_V_PAT)
_sv("LUACOMP_NAME", "LuaComp")

--[[
	ast.lua - Generates a structure for use in preprocessing.

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

local function nextc(f, c)
	c = c or 1
	return f:read(c)
end

local function peek(f, c)
	c = c or 1
	local z = f:read(c)
	f:seek("cur", -c)
	return z
end

local function skip(f, c)
	c = c or 1
	return f:seek("cur", c)
end

local ws = {
	["\t"] = true,
	[" "] = true
}

local function parse_hex(f)
	local lc = " "
	local hex = ""
	while (48 <= lc:byte() and lc:byte() <= 57) or (97 <= lc:byte() and lc:byte() <= 102) or (65 <= lc:byte() and lc:byte() <= 70) do
		lc = nextc(f)
		if (48 <= lc:byte() and lc:byte()) <= 57 or (97 <= lc:byte() and lc:byte() <= 102) or (65 <= lc:byte() and lc:byte() <= 70) then
			hex = hex .. lc
		end
	end
	return tonumber(hex, 16)
end

local function parse_number(f, c)
	local lc = " "
	local num = c
	while 48 <= lc:byte() and lc:byte() <= 57 do
		lc = nextc(f)
		if (48 <= lc:byte() and lc:byte() <= 57) then
			num = num .. lc
		end
	end
	return tonumber(hex, 10)
end

local esct = {
	["t"] = "\t",
	["n"] = "\n",
	["r"] = "\r",
	["\\"] = "\\\\"
}

for i=0, 9 do
	esct[tostring(i)] = string.char(i)
end

local function parse_dblquote(f)
	local val = ""
	while peek(f) ~= "\"" do
		local c = nextc(f)
		if (peek(f) == "\n" or peek(f) == "\r") then
			return nil, "Unexpected end of line"
		end
		if (c == "\\") then
			if (esct[peek(f)]) then
				c = esct[peek(f)]
				skip(f)
			else
				c = nextc(f)
			end
		end
		val = val .. c
	end
	skip(f)
	return val
end

local function parse_snglquote(f)
	local val = ""
	while peek(f) ~= "\'" do
		local c = nextc(f)
		if (peek(f) == "\n" or peek(f) == "\r") then
			return nil, "Unexpected end of line"
		end
		if (c == "\\") then
			if (esct[peek(f)]) then
				c = esct[peek(f)]
				skip(f)
			else
				c = nextc(f)
			end
		end
		val = val .. c
	end
	skip(f)
	return val
end

local function parse_envarg(f)
	local val = ""
	while peek(f) ~= ")" do
		if (peek(f) == "\n" or peek(f) == "\r") then
			return nil, "Unexpected end of line"
		end
		val = val .. nextc(f)
	end
	skip(f)
	return val
end

local function parse_directive(f)
	local lc = "_"
	local name = ""
	local args = {}
	local carg = ""
	while not ws[lc] do
		lc = nextc(f)
		if (lc == "\n" or lc == "\r") then
			if (lc == "\r" and peek(f) == "\n") then skip(f) end
			return {type="directive", name=name}
		elseif not ws[lc] then
			name = name .. lc
		end
	end
	while true do
		lc = nextc(f)
		if (lc == "\n" or lc == "\r") then
			if (lc == "\r" and peek(f) == "\n") then skip(f) end
			return {type="directive", name=name, args=args}
		elseif lc == "0" and peek(f) == "x" then
			skip(f)
			local val = parse_hex(f)
			args[#args+1] = val
		elseif 48 <= lc:byte() and lc:byte() <= 57 then
			local val = parse_number(f, lc)
			args[#args+1] = val
		elseif lc == "\"" then
			local val, e = parse_dblquote(f)
			if not val then return val, e end
			args[#args+1] = val
		elseif lc == "\'" then
			local val, e = parse_snglquote(f)
			if not val then return val, e end
			args[#args+1] = val
		elseif lc == "$" and peek(f) == "(" then
			skip(f)
			local val = parse_envarg(f)
			if not os.getenv(val) then return nil, "Enviroment variable `"..val.."' does not exist." end
			args[#args+1] = os.getenv(val)
		elseif not ws[lc] then
			return nil, "Syntax error"
		end
	end
end

local function mkast(f, n)
	io.stderr:write("PROC\t",n,"\n")
	local lc = " "
	local lpos = 1
	local ilpos = 1
	local tree = {}
	local code = ""
	local branches = {}
	local function add_code()
		tree[#tree+1] = {type="code", data=code, file=n, line=lpos}
		code = ""
	end
	local function parse_error(e)
		io.stderr:write("ERROR:"..n..":"..lpos..": "..e.."\n")
		os.exit(1)
	end
	while lc and lc ~= "" do
		lc = nextc(f)
		if (lc == "-" and ilpos == 1) then
			if (peek(f, 2) == "-#") then --Directive
				add_code()
				skip(f, 2)
				local d, r = parse_directive(f)
				if not d then
					parse_error(r)
				end
				d.line = lpos
				d.file = n
				lpos = lpos+1
				tree[#tree+1] = d
			else
				code = code .. lc
				ilpos = ilpos+1
			end
		elseif (lc == "/" and ilpos == 1) then
			if (peek(f, 2) == "/#") then --Directive
				add_code()
				skip(f, 2)
				local d, r = parse_directive(f)
				if not d then
					parse_error(r)
				end
				d.line = lpos
				d.file = n
				lpos = lpos+1
				tree[#tree+1] = d
			else
				code = code .. lc
				ilpos = ilpos+1
			end
		elseif (lc == "$" and peek(f) == "(") then
			add_code()
			skip(f)
			local val, e = parse_envarg(f)
			if not val then
				parse_error(e)
			end
			tree[#tree+1] = {type="envvar", var=val, file=n, line=lpos}
		elseif (lc == "@" and peek(f, 2) == "[[") then
			add_code()
			skip(f, 2)
			local val = ""
			while peek(f, 2) ~= "]]" do
				val = val .. nextc(f)
			end
			tree[#tree+1] = {type="lua", code=val, file=n, line=lpos}
			skip(f, 2)
		elseif (lc == "@" and peek(f, 2) == "[{") then
			add_code()
			skip(f, 2)
			local val = ""
			while peek(f, 2) ~= "}]" do
				val = val .. nextc(f)
			end
			tree[#tree+1] = {type="lua_r", code=val, file=n, line=lpos}
			skip(f, 2)
		elseif (lc == "\r" or lc == "\n") then
			if (lc == "\r" and peek(f) == "\n") then
				skip(f)
			end
			lpos = lpos+1
			ilpos = 1
			code = code .. "\n"
		else
			code = code .. (lc or "")
			ilpos = ilpos+1
		end
	end
	add_code()
	return tree
end

--[[
	generator.lua - Generates the code.

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

local function lua_escape(code)
   return code:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n")
end

local directives = {}

local function generate(ast)
   local lua_code = ""
   for i=1, #ast do
      local leaf = ast[i]
      if (leaf.type == "lua") then
         lua_code = lua_code .. leaf.code
      elseif (leaf.type == "directive") then
         local stargs = {}
         for i=1, #leaf.args do
            local arg = leaf.args[i]
            if (type(arg) == "string") then
               stargs[i] = "\""..lua_escape(arg).."\""
            elseif (type(arg) == "number") then
               stargs[i] = tostring(arg)
            end
         end
         lua_code = lua_code .. "call_directive(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.name.."\","..table.concat(stargs, ",")..")"
      elseif (leaf.type == "envvar") then
         lua_code = lua_code .. "put_env(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.var.."\")"
      elseif (leaf.type == "code") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",\"" .. lua_escape(leaf.data) .. "\")"
      elseif (leaf.type == "lua_r") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",tostring("..leaf.code.."))"
      else
         io.stderr:write("ERROR: Internal catastrophic failure, unknown type "..leaf.type.."\n")
         os.exit(1)
      end
      lua_code = lua_code .. "\n"
   end
   local env = {code = ""}
   local function run_away_screaming(fpos, err)
      io.stdout:write("ERROR: "..fpos..": "..err.."\n")
      os.exit(1)
   end
   local function call_directive(fpos, dname, ...)
      if (not directives[dname]) then
         run_away_screaming(fpos, "Invalid directive name `"..dname.."'")
      end
      local r, er = directives[dname](env, ...)
      if (not r) then
         run_away_screaming(fpos, er)
      end
   end
   local function put_env(fpos, evar)
      local e = os.getenv(evar)
      if not e then
         run_away_screaming(fpos, "Enviroment variable `"..evar.."' does not exist!")
      end
      env.code = env.code .. "\""..lua_escape(e).."\""
   end
   local function put_code(fpos, code)
      env.code = env.code .. code --not much that can fail here...
   end
   local fenv = {}
   for k, v in pairs(_G) do
      fenv[k] = v
   end
   fenv._G = fenv
   fenv._ENV = fenv
   fenv.call_directive = call_directive
   fenv.put_code = put_code
   fenv.put_env = put_env
   local func = assert(load(lua_code, "=(generated code)", "t", fenv))
   func()
   return env.code
end

--[[
	directive_provider.lua - Provides preprocessor directives

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

---#include "directives/define.lua"

function directives.include(env, file)
	if (not os.execute("stat "..file..">/dev/null")) then
		return false, "File `"..file.."' does not exist!"
	end
	local f = io.open(file, "r")
	local fast = mkast(f, file)
	local code = generate(fast)
	env.code = env.code .. "\n" .. code .. "\n"
	return true
end

local warned = false
function directives.loadmod(env, mod)
	if not warned then
		io.stderr:write("Warning: loadmod is depreciated and unsafe. The API differs from luapreproc.\n")
		warned = true
	end
	if (not os.execute("stat "..file..">/dev/null")) then
		return false, "Module `"..file.."' does not exist!"
	end
	local modname, func = dofile(mod)
	directives[modname] = func
	return true
end


--[[
	cfg/minifier_providers.lua - Provides minifier providers.

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

local providers = {}

function providers.luamin(cin)
	local fn = os.tmpname()
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	local lmh = io.popen("luamin -f "..fn.." 2>&1", "r")
	local dat = lmh:read("*a")
	local stat, _, code = lmh:close()
	if (code ~= 0) then
		return false, dat
	end
	return dat
end

function providers.none(cin)
	return cin
end

local argparse = require("argparse")

local parser = argparse(arg[0], "LuaComp v"..LUACOMP_VERSION.."\nA Lua preprocessor+postprocessor.")
parser:argument("input", "Input file (- for STDIN)")
parser:option("-O --output", "Output file. (- for STDOUT)", "-")
parser:option("-m --minifier", "Sets the minifier", "none")
parser:option("-x --executable", "Makes the script an executable (default: current lua version)"):args "?"
local args = parser:parse()
local file = args.input
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
local ver = _VERSION:lower():gsub(" ", "")
if jit then
	ver = "luajit"
end
if (args.executable) then
	of:write("#!/usr/bin/env ", args.executable[1] or ver, "\n")
end
of:write(rcode)
of:close()
f:close()
