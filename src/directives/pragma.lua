-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local pragma_hooks = {
	include_once = function(env, value)
		if value and value ~= 0 then

		end
	end
}

function directives.pragma(env, key, value)
	--luacomp.warning(key.."\t"..value)
	if not env.pragmas[key] then
		return nil, "unknown pragma "..key
	end
	env.pragmas[key] = value
	return true
end