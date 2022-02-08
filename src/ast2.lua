-- AST Generator v2: Belkan Boogaloo
-- Hopefully faster than v1
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
local ast = {}
do
	local ws = "\t "

	function ast.str_to_stream(str, file)
		local s = {
			str = str,
			pos = 1,
			file = file or "(unknown)"
		}
		function s:next(c)
			c = c or 1
			--dprint(c)
			local d = self.str:sub(self.pos, self.pos+c-1)
			self.pos = self.pos + c
			return d
		end

		function s:peek(c)
			c = c or 1
			if (c < 0) then
				return self.str:sub(self.pos+c, self.pos-1)
			end
			return self.str:sub(self.pos, self.pos+c-1)
		end

		function s:rewind(c)
			c = c or 1
			self.pos = self.pos - c
			return self.pos
		end

		function s:skip(c)
			c = c or 1
			self.pos = self.pos + c
			return self.pos
		end

		function s:set(c)
			--dprint(c)
			self.pos = c or self.pos
			return self.pos
		end

		function s:tell()
			return self.pos
		end

		function s:size()
			return #self.str
		end

		function s:next_instance(pat, raw)
			local st, en = self.str:find(pat, self.pos, raw)
			if not st then return nil, "not found" end
			self.pos = en+1
			return self.str:sub(st, en)
		end

		function s:get_yx() -- it *is* yx
			local pos = 0
			local line = 1
			while pos < self.pos do
				local newpos = self.str:find("\n", pos+1)
				if not newpos then return line+1, 0 end
				if newpos > self.pos then
					return line, self.pos-pos
				end
				line = line + 1
				pos = newpos
			end
			return line, 1
		end

		return s
	end

	local esct = {
		["t"] = "\t",
		["n"] = "\n",
		["r"] = "\r",
		--["\\"] = "\\\\"
	}

	function ast.parser_error(str, err)
		local y, x = str:get_yx()
		--print(y, x)
		lc_error("@[{_GENERATOR.fname}]", string.format("%s(%d:%d): %s\n", str.file, y or 0, x or 0, err))
	end

	function ast.unescape(escaped_string)
		local i = 1
		local out_string = ""
		while i <= #escaped_string do
			local c = escaped_string:sub(i,i)
			if (c == "\\") then
				i = i + 1
				local nc = escaped_string:sub(i,i)
				if esct[nc] then
					out_string = out_string .. esct[nc]
				else
					out_string = out_string .. nc
				end
			else
				out_string = out_string .. c
			end
			i = i + 1
		end
		return out_string
	end

	function ast.remove_escapes(escaped_string)
		local i = 1
		local out_string = ""
		while i <= #escaped_string do
			local c = escaped_string:sub(i,i)
			--lc_warning(c, tostring(i).." "..#escaped_string)
			if (c == "\\") then
				i = i + 1
			else
				out_string = out_string .. c
			end
			i = i + 1
		end
		--lc_warning("debug", out_string)
		return out_string
	end

	function ast.back_escape_count(str, start)
		local i=2
		while str:peek(-i):sub(1,1) == "\\" do
			i = i + 1
			if (str:tell()-i < start) then
				ast.error(str, "internal error")
			end
		end
		--lc_warning(tostring(i), #str:peek(1-i).." "..str:peek(1-i))
		return str:peek(1-i)
	end

	function ast.parse_quote(str)
		local spos = str:tell()
		while true do
			if not str:next_instance("\'") then
				ast.parser_error(str, "unclosed string")
			end
			local rpos = str:tell()
			str:set(spos)
			if str:next_instance("\n") then
				if rpos > str:tell() then
					ast.parser_error(str, "unclosed string")
				end
			end
			str:set(rpos)
			if str:peek(-1) == "\\" then
				local parsed = ast.remove_escapes(ast.back_escape_count(str, spos))
				if parsed:sub(#parsed) == "\'" then
					goto found_end
				end
			else
				goto found_end
			end
		end
		::found_end::
		local epos = str:tell()
		local amt = epos-spos-1
		str:set(spos)
		local esc = str:next(amt)
		str:skip(1)
		return ast.unescape(esc)
	end

	function ast.parse_dblquote(str)
		local spos = str:tell()
		while true do
			if not str:next_instance("\"") then
				ast.parser_error(str, "unclosed string")
			end
			local rpos = str:tell()
			str:set(spos)
			if str:next_instance("\n") then
				if rpos > str:tell() then
					ast.parser_error(str, "unclosed string")
				end
			end
			str:set(rpos)
			--lc_warning(str:peek(-2), "test")
			if str:peek(-2):sub(1,1) == "\\" then
				local parsed = ast.remove_escapes(ast.back_escape_count(str, spos))
				if parsed:sub(#parsed) == "\"" then
					goto found_end
				end
			else
				goto found_end
			end
			--str:set(rpos)
		end
		::found_end::
		local epos = str:tell()
		local amt = epos-spos-1
		str:set(spos)
		--dprint(spos, amt)
		local esc = str:next(amt)
		--print(esc)
		str:skip(1)
		return ast.unescape(esc)
	end

	function ast.parse_hex(str)
		local hex = str:next_instance("%x+")
		if not hex then
			ast.parser_error(str, "internal error")
		end
		return tonumber(hex, 16)
	end

	function ast.parse_number(str)
		local num = str:next_instance("%d+")
		if not num then
			ast.parser_error(str, "internal error")
		end
		return tonumber(num, 10)
	end

	function ast.parse_envvar(str)
		local name = str:next_instance("[^)]+")
		if not name then
			ast.parser_error(str, "unclosed shell var")
		end
		str:skip(1)
		return name
	end

	-- [{...}]
	function ast.parse_span(str)
		local spos = str:tell()
		if not str:next_instance("}]", true) then
			ast.parser_error(str, "unclosed block")
		else
			local rpos = str:tell()
			str:set(spos)
			if str:next_instance("\n") then
				if str:tell() < rpos then
					str:set(spos)
					ast.parser_error(str, "unclosed span")
				end
			end
			str:set(rpos)
		end
		local epos = str:tell()
		str:set(spos)
		local data = str:next(epos-spos-2)
		str:skip(2)
		return data
	end

	-- [[...]]
	function ast.parse_block(str)
		local spos = str:tell()
		if not str:next_instance("]]") then
			ast.parser_error(str, "unclosed block")
		end
		local epos = str:tell()
		str:set(spos)
		local data = str:next(epos-spos-2)
		str:skip(2)
		return data
	end

	function ast.parse_directive(str) -- And now we start getting more complex.
		local name = str:next_instance("[^ ]+")
		local args = {}
		while true do
			local spos = str:tell()
			if not str:next_instance(" +") then
				break
			else
				local rpos = str:tell()
				if str:next_instance("\n") then
					if str:tell() < rpos then
						str:set(spos)
						break
					end
					str:set(rpos)
				end
			end
			local apos = str:tell()
			if str:peek(2) == "0x" then
				str:skip(2)
				local n = ast.parse_hex(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed hex")
				end
				table.insert(args, n)
			elseif str:peek():find("%d") then
				local n = ast.parse_number(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed number")
				end
				table.insert(args, n)
			elseif str:peek() == "\"" then
				str:skip(1)
				local sval = ast.parse_dblquote(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed string")
				end
				table.insert(args, sval)
			elseif str:peek() == "\'" then
				str:skip(1)
				local sval = ast.parse_quote(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed string")
				end
				table.insert(args, sval)
			elseif str:peek(2) == "$".."(" then -- i have to avoid the funny
				str:skip(2)
				local sval = ast.parse_envvar(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed argument")
				end
				table.insert(args, {type="evar", val=sval})
			elseif str:peek(3) == "@".."[{" then
				str:skip(3)
				local sval = ast.parse_span(str)
				local c = str:peek()
				if c ~= " " and c ~= "\n" and c ~= "" then
					str:set(apos)
					ast.parser_error(str, "malformed code block")
				end
				table.insert(args, {type="lua_span", val=sval})
			elseif str:peek() == "\n" then
				break
			else
				ast.parser_error(str, "unknown arg type")
			end
			if str:peek() == "\n" then
				break
			end
		end
		return {
			type="directive",
			name = name,
			args = args
		}
	end

	function ast.find_first(str, onfind, ...)
		local t = table.pack(...)
		local spos = str:tell()
		local epos = math.huge
		local ematch
		for i=1, t.n do
			str:set(spos)
			local m = str:next_instance(t[i], true)
			if m then
				if str:tell() < epos then
					if onfind then 
						if not onfind(str, m) then goto continue end
					end
					epos = str:tell()
					ematch = m
				end
			end
			::continue::
		end
		if ematch then
			str:set(epos)
		else
			str:set(spos)
		end
		return ematch
	end

	function ast.add_debugging_info(list, str, sx, sy)
		if DEBUGGING then
			local node = list[#list]
			node.sx = sx
			node.sy = sy
			node.ey, node.ex = str:get_yx()
			node.file = str.file
			if not str.file then
				luacomp.error("Node has no file!\n"..debug.traceback())
			end
		end
	end

	-- And now we parse
	function ast.parse(str)
		local cast = {}
		while true do
			local spos = str:tell()
			--dprint("searching")
			local match = ast.find_first(str, function(str, submatch)
				if (submatch == "--#") then
					--dprint("directive?")
					local i=4
					while true do
						if str:peek(-i):sub(1,1) == "\n" or str:peek(-i):sub(1,1) == "" or str:tell() == 4 then
							--dprint("found newline, we're cool")
							return true
						elseif not ws:find(str:peek(-i):sub(1,1)) then
							--dprint("found non-whitespace character "..string.byte(str:peek(-i):sub(1,1))..str:peek(-i):sub(1,1))
							return false
						end
						i = i + 1
					end
				end
				return true
			end, "--".."#", "$".."[[", "@".."[[", "$".."[{", "@".."[{", "$".."(", "//".."##") -- trust me, this was needed
			--dprint("searched")
			local sy, sx = str:get_yx()
			if not match then
				--dprint("not found")
				table.insert(cast, {type="content", val=str:next(str:size())})
				ast.add_debugging_info(cast, str, sx, sy)
				break
			end
			local epos = str:tell()
			local size = (epos-#match)-spos
			if size > 0 then
				str:set(spos)
				local chunk = str:next(size)
				if not chunk:match("^%s+$") then
					table.insert(cast, {type="content", val=chunk})
					ast.add_debugging_info(cast, str, sx, sy)
				end
				str:skip(#match)
			end
			--dprint("match: "..match)
			if match == "--".."#" or match == "//".."##" then
				--str:skip(3)
				table.insert(cast, ast.parse_directive(str))
			elseif match == "$".."[[" then
				local blk = ast.parse_block(str)
				table.insert(cast, {type="shell_block", val=blk})
			elseif match == "@".."[[" then
				local blk = ast.parse_block(str)
				table.insert(cast, {type="lua_block", val=blk})
			elseif match == "$".."[{" then
				local span = ast.parse_span(str)
				table.insert(cast, {type="shell_span", val=span})
			elseif match == "@".."[{" then
				local span = ast.parse_span(str)
				--print(span)
				table.insert(cast, {type="lua_span", val=span})
			elseif match == "$".."(" then
				local var = ast.parse_envvar(str)
				table.insert(cast, {type="evar", val=var})
			else
				ast.parser_error(str, "internal compiler error")
			end
			--dprint("Parsed")
			ast.add_debugging_info(cast, str, sx, sy)
		end

		return cast
	end
end
