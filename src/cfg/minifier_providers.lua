--[[
	cfg/minifier_providers.lua - Provides minifier providers.

   Copyright 2019 Adorable-Catgirl

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]

local providers = {}

function providers.luamin(cin)
	local fn = os.tmpname()
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	local lmh = io.popen("luamin -f "..fn.." 2>&1", "r")
	local dat = lmh:read("*a")
	local stat, _, code = lmh:close()
	if (code ~= 0) then
		return false, dat
	end
	return dat
end

function providers.none(cin)
	return cin
end