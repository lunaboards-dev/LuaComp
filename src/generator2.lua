-- Generator v2: Borderless Edition
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local generator = {}

do
	function generator.parse_ast(file, ast)
		local gcode = ""
		for i=1, #ast do
			local leaf = ast[i]
			if DEBUGGING then
				if not leaf.file then
					local linfo = {}
					for k, v in pairs(leaf) do
						table.insert(linfo, tostring(k).."\t"..tostring(v))
					end
					luacomp.error("Node has no file!\n"..debug.traceback().."\n"..table.concat(linfo, "\n"))
				end
				table.insert(__DSYM, {
					sx = leaf.sx,
					sy = leaf.sy,
					ex = leaf.ex,
					ey = leaf.ey,
					file = leaf.file
				})
				gcode = gcode .. string.format("push_debuginfo(%d)\n", #__DSYM)
			end
			if leaf.type == "directive" then
				gcode = gcode .. string.format("call_directive(%q,", leaf.name)
				local pargs = {}
				for i=1, #leaf.args do
					if type(leaf.args[i]) ~= "table" then
						table.insert(pargs, string.format("%q", leaf.args[i]))
					elseif leaf.args[i].type == "lua_span" then
						table.insert(pargs, leaf.args[i].val)
					elseif leaf.args[i].type == "evar" then
						table.insert(pargs, string.format("svar.get(%q)", leaf.args[i].val))
					end
				end
				gcode = gcode .. table.concat(pargs, ",")..")\n"
			elseif leaf.type == "lua_block" then
				gcode = gcode .. leaf.val .. "\n"
			elseif leaf.type == "shell_block" then
				gcode = gcode .. string.format("shell_write(%q)\n", leaf.val)
			elseif leaf.type == "content" then
				gcode = gcode .. string.format("write_out(%q)\n", leaf.val)
			elseif leaf.type == "lua_span" then
				gcode = gcode .. "write_out("..leaf.val..")\n"
			elseif leaf.type == "shell_span" then
				gcode = gcode .. string.format("write_out(svar.get(%q))\n", leaf.val)
			elseif leaf.type == "evar" then
				gcode = gcode .. string.format("write_out(string.format(\"%%q\", svar.get(%q)))\n", leaf.val)
			end
		end
		return gcode
	end

	function generator.run_gcode(fname, gcode)
		fname = fname or "(unknown)"
		local env = {
			code = "",
			fname = fname,
			pragmas = {
				include_file_name = "n",
				prefix_local_file_numbers = "n",
				wrap_includes = "n"
			}
		}
		local fenv = {}
		for k, v in pairs(_G) do
			fenv[k] = v
		end
		fenv._G = fenv
		fenv._GENERATOR = env
		local lsym
		function fenv.push_debuginfo(idx)
			local ent = __DSYM[idx]
			local linecount = 0
			for l in env.code:gmatch("[^\n]*") do
				linecount = linecount+1
			end
			local x = 1
			while true do
				x = x + 1
				local c = env.code:sub(#env.code-x, #env.code-x)
				if c == "\n" or c == "" then
					break
				end
			end
			ent.fx = x-1
			ent.fy = linecount
			if lsym then
				local lent = __DSYM[idx]
				lent.fey = ent.fy
			end
			lsym = idx
		end

		local function debug_add_tag(ttype, ...)
			local alist = table.pack(...)
			for i=1, #alist do
				alist[i] = tostring(alist[i])
			end
			__DSYM[lsym].tag = string.format("TYPE[%s=%s]", ttype, table.concat(alist,","))
			__DSYM[lsym].tagv = {type=ttype, vals=table.pack(...)}
		end
		
		function fenv.call_directive(dname, ...)
			if not directives[dname] then lc_error("@[{_GENERATOR.fname}]", "invalid directive "..dname) end
			local r, er = directives[dname](env, ...)
			if not r then lc_error("directive "..dname, er) end
			debug_add_tag("CALL_DIR", dname, ...)
		end

		function fenv.write_out(code)
			env.code = env.code .. code
			debug_add_tag("CODE", #tostring(code))
		end

		function fenv.shell_write(cmd)
			local tmpname = os.tmpname()
			local f = io.open(tmpname, "w")
			f:write(cmd)
			f:close()
			local h = io.popen(os.getenv("SHELL").." "..tmpname, "r")
			local r = h:read("*a"):gsub("%s+$", ""):gsub("^%s+", "")
			env.code = env.code .. r
			h:close()
			debug_add_tag("SHELL", cmd, #r)
		end

		assert(load(gcode, "="..fname, "t", fenv))()

		if DEBUGGING then

		end

		return env.code
	end
end