--[[
	directive_provider.lua - Provides preprocessor directives

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

--#include "src/cfg/directive_providers.lua"
--#include "src/directives/define.lua"
--#include "src/directives/include.lua"
--#include "src/directives/loadmod.lua"
--#include "src/directives/error.lua"

setmetatable(directives, {__index=function(t, i)
   for i=1, #directive_paths do
      if (os.execute("stat "..directive_paths[i].."/"..i..".lua 1>/dev/null 2>&1")) then
         directives[i] = loadfile(directive_paths[i].."/"..i..".lua")()
         return directives[i]
      end
   end
end})

local function preload_directives()
   --Do this in the best way possible
   for i=1, #directive_paths do
      if (os.execute("stat "..directive_paths[i].." 1>/dev/null 2>&1")) then
         local fh = io.popen("ls "..directive_paths[i], "r")
         for line in fh:lines() do
            if (line:match("%.lua$")) then
               directives[line:sub(1, #line-4)] = loadfile(directive_paths[i].."/"..line)()
            end
         end
      end
   end
end