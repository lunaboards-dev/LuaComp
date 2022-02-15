-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

function directives.include(env, file, asmod)
	local rfile = file
	--luacomp.warning("relative_include\t"..env.pragmas.relative_include)
	if env.pragmas.relative_include == "y" or luacomp.experimental.relative_include then
		--luacomp.warning("Experimental relative include enabled!")
		if not env.fname:find("/") then
			rfile = file
		else
			rfile = env.fname:gsub("/[^/]+$", "/")..file
		end
	end
	local sr, err = stat.stat(rfile)
	if not sr then return false, err end
	--[[local f = io.open(file, "r")
	local fast = mkast(f, file)
	fast.file = file
	local code = generate(fast)
	env.code = env.code .. code .. "\n"]]
	if asmod then env.code = env.code .. "local "..asmod.." = (function()\n" end
	if env.pragmas.include_file_name == "y" then
		env.code = env.code .. "-- BEGIN " .. file .. "\n"
	end
	local code = luacomp.process_file(rfile, rfile) .. "\n"
	if env.pragmas.prefix_local_file_numbers == "y" then
		local newcode = ""
		local i = 1
		for match in code:gmatch("[^\n]*") do
			newcode = newcode .. "--[["..i.."]] "..match.."\n"
			i = i + 1
		end
		code = newcode
	end
	env.code = env.code .. code
	if env.pragmas.include_file_name == "y" then
		env.code = env.code .. "-- END " .. file .. "\n"
	end
	if asmod then env.code = env.code .. "end)()\n" end
	return true
end