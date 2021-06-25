--[[
	directive_provider.lua - Provides preprocessor directives
]]
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

--#include "src/cfg/directive_providers.lua"
--#include "src/directives/define.lua"
--#include "src/directives/include.lua"
--#include "src/directives/loadmod.lua"
--#include "src/directives/error.lua"

setmetatable(directives, {__index=function(t, i)
   for i=1, #directive_paths do
      if stat.stat(directive_paths[i].."/"..i..".lua") then
         providers[i] = loadfile(directive_paths[i].."/"..i..".lua")()
         return providers[i]
      end
   end
end})

local function preload_directives()
   --Do this in the best way possible
   for i=1, #directive_paths do
      if stat.stat(directive_paths[i]) then
         for ent in dirent.files(directive_paths[i]) do
            if ent:match("%.lua$") then
               providers[ent:sub(1, #ent-4)] = loadfile(directive_paths[i].."/"..ent)()
            end
         end
      end
   end
end