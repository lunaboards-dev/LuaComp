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
	while (48 <= lc:byte() and lc:byte() <= 57) or (97 <= lc:byte() and lc:byte() <= 102) or (65 <= lc:byte() and lc:byte() <= 70) and lc do
		lc = nextc(f)
		if (48 <= lc:byte() and lc:byte()) <= 57 or (97 <= lc:byte() and lc:byte() <= 102) or (65 <= lc:byte() and lc:byte() <= 70) and lc then
			hex = hex .. lc
		end
	end
	return tonumber(hex, 16)
end

local function parse_number(f, c)
	local lc = " "
	local num = c
	while 48 <= lc:byte() and lc:byte() <= 57 and lc do
		lc = nextc(f)
		if (48 <= lc:byte() and lc:byte() <= 57) and lc then
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
		elseif (not peek(f)) then
			return nil, "Unexpected end of file"
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
		elseif (not peek(f)) then
			return nil, "Unexpected end of file"
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
		elseif (not peek(f)) then
			return nil, "Unexpected end of file"
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
		elseif lc == "@" and peek(f, 2) == "[{" then
			skip(f, 2)
			local val = ""
			while peek(f, 2) ~= "}]" do
				val = val .. nextc(f)
			end
			args[#args+1] = {type="lua_var", val}
			skip(f, 2)
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
		elseif (lc == "$" and peek(f, 2) == "[[") then
			add_code()
			skip(f, 2)
			local val = ""
			while peek(f, 2) ~= "]]" do
				val = val .. nextc(f)
			end
			tree[#tree+1] = {type="shell", code=val, file=n, line=lpos}
			skip(f, 2)
		elseif (lc == "$" and peek(f, 2) == "[{") then
			add_code()
			skip(f, 2)
			local val = ""
			while peek(f, 2) ~= "}]" do
				val = val .. nextc(f)
			end
			tree[#tree+1] = {type="shell_r", code=val, file=n, line=lpos}
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