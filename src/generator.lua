--[[
	generator.lua - Generates the code.

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

local function lua_escape(code)
   return code:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n")
end

local directives = {}

local function generate(ast)
   local lua_code = ""
   for i=1, #ast do
      local leaf = ast[i]
      if (leaf.type == "lua") then
         lua_code = lua_code .. code
      elseif (leaf.type == "directive") then
         local stargs = {}
         for i=1, #leaf.args do
            local arg = leaf.args[i]
            if (type(arg) == "string") then
               stargs[i] = "\""..lua_escape(arg).."\""
            elseif (type(arg) == "number") then
               stargs[i] = tostring(arg)
            end
         end
         lua_code = lua_code .. "call_directive(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.name.."\","..table.concat(stargs, ",")..")"
      elseif (leaf.type == "envvar") then
         lua_code = lua_code .. "put_env(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.name.."\")"
      elseif (leaf.type == "code") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",\"" .. lua_escape(leaf.data) .. "\")"
      elseif (leaf.type == "lua_r") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",tostring("..leaf.code.."))"
      else
         io.stderr:write("ERROR: Internal catastrophic failure, unknown type "..leaf.type.."\n")
         os.exit(1)
      end
   end
   local env = {code = ""}
   local function run_away_screaming(fpos, err)
      io.stdout:write("ERROR: "..fps..": "..err.."\n")
      os.exit(1)
   end
   local function call_directive(fpos, dname, ...)
      if (not directives[dname]) then
         run_away_screaming(fpos, "Invalid directive name `"..dname.."'")
      end
      local r, er = directives[dname](env, ...)
      if (not r) then
         run_away_screaming(fpos, er)
      end
   end
   local function put_env(fpos, env)
      local e = os.getenv(env)
      if not e then
         run_away_screaming(fpos, "Enviroment variable `"..env.."' does not exist!")
      end
      env.code = env.code .. "\""..lua_escape(e).."\""
   end
   local function put_code(fpos, code)
      env.code = env.code .. code --not much that can fail here...
   end
   local fenv = {}
   for k, v in pairs(_G) do
      fenv[k] = v
   end
   fenv._G = fenv
   fenv._ENV = fenv
   fenv.call_directive = call_directive
   fenv.put_code = put_code
   fenv.put_env = put_env
   local func = assert(load(lua_code, "=(generated code)", "t", fenv))
   func()
   return env.code
end