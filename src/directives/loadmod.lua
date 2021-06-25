-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local warned = false
function directives.loadmod(env, mod)
	if not warned then
		lc_warning("@[{_GENERATOR.fname}]", "loadmod is depreciated and unsafe. The API differs from luapreproc. Use the include paths!")
		warned = true
	end
	--if (not os.execute("stat "..file..">/dev/null")) then
	local sr, se = stat.stat(file)
	if not sr then
		return false, se
	end
	local modname, func = dofile(mod)
	directives[modname] = func
	return true
end