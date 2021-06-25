--[[
	staticinit.lua - Main file of LuaComp, directly includes argparse.
]]

-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local argparse = (function()
--#include "src/argparse.lua"
end)()

--#include "src/application.lua"
