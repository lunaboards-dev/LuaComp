-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local warned = false
function directives.loadmod(env, mod)
	if not warned then
		io.stderr:write("Warning: loadmod is depreciated and unsafe. The API differs from luapreproc. Use the include paths!\n")
		warned = true
	end
	if (not os.execute("stat "..file..">/dev/null")) then
		return false, "Module `"..file.."' does not exist!"
	end
	local modname, func = dofile(mod)
	directives[modname] = func
	return true
end