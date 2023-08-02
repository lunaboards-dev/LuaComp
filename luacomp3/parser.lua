local lpp = require("libpreproc")
local p = function(a)return lpp.pattern(a, true)end
local parser = {}

function parser:single_pass()

end

local span = lpp.block(p"[{", p"}]")
local block = lpp.block(p"[[", p"]]")
local parens = lpp.block(p"(", p")")
local luacode = lpp.pattern("@(%d*)")
local shellcode = p"$"
local directive = lpp.pattern("--#!*")

function parser:init()
	local parse = lpp.instance()

	--Lua code span
	parse:add_token(lpp.prefix(luacode, span), function(stream, instance, result)
		if #result.matches == 2 and result.matches[1] and result.matches[1] ~= "" then
			result.matches.pass = tonumber(result.matches[1], 10)
			if (result.matches.pass > 0) then
				instance:emit(string.format("@%d[{%s}]", result.matches.pass, result.matches[2]))
				return
			end
		end
		instance:write(string.format("write(%s)", result.matches[#result.matches]))
	end)

	-- Lua code block
	parse:add_token(lpp.prefix(luacode, block), function(stream, instance, result)
		--print("<m>", table.unpack(result.matches))
		if #result.matches == 2 and result.matches[1] and result.matches[1] ~= "" then
			result.matches.pass = tonumber(result.matches[1], 10)
			if (result.matches.pass > 0) then
				instance:emit(string.format("@%d[[%s]]", result.matches.pass, result.matches[2]))
				return
			end
		end
		instance:write(result.matches[#result.matches])
	end)

	-- Shell variable
	parse:add_token(lpp.prefix(shellcode, span), function(stream, instance, result)
		instance:write(string.format("write(os.getenv(%q))", result.matches[1]))
	end)

	-- Shell variable, wrapped in quotes
	parse:add_token(lpp.prefix(shellcode, parens), function(stream, instance, result)
		instance:write(string.format("write('\"'..os.getenv(%q)..'\"')", result.matches[1]))
	end)

	-- Shell block
	parse:add_token(lpp.prefix(shellcode, block), function(stream, instance, matches)
	
	end)
	self.parser = parse
end

function parser:parse(code)
	self.parser:compile(code)
	print(self.parser.code)
	local res = self.parser:generate()
	print(res)
end

return parser