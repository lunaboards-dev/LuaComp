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
		local env = {code = "", fname=fname}
		local fenv = {}
		for k, v in pairs(_G) do
			fenv[k] = v
		end
		fenv._G = fenv
		fenv._GENERATOR = env
		function fenv.call_directive(dname, ...)
			if not directives[dname] then lc_error("@[{_GENERATOR.fname}]", "invalid directive "..dname) end
			local r, er = directives[dname](env, ...)
			if not r then lc_error("@[{_GENERATOR.fname}]", er) end
		end

		function fenv.write_out(code)
			env.code = env.code .. code
		end

		function fenv.shell_write(cmd)
			local tmpname = os.tmpname()
			local f = io.open(tmpname, "w")
			f:write(cmd)
			f:close()
			local h = io.popen(os.getenv("SHELL").." "..tmpname, "r")
			env.code = env.code .. h:read("*a")
			h:close()
		end

		assert(load(gcode, "="..fname, "t", fenv))()

		return env.code
	end
end