-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local function _sv(k, v)
	_G[k] = v
	svar.set(k, v)
	--os.setenv(k, tostring(v))
end

_sv("LUACOMP_V_MAJ", 2)
_sv("LUACOMP_V_MIN", 0)
_sv("LUACOMP_V_PAT", 2)
_sv("LUACOMP_VERSION", LUACOMP_V_MAJ.."."..LUACOMP_V_MIN.."."..LUACOMP_V_PAT)
_sv("LUACOMP_NAME", "LuaComp")