--[[
	generator.lua - Generates the code.
]]

-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local function lua_escape(code)
   return code:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n")
end

local function shell_escape(code)
   return code:gsub("\\%[", "[")
end

local function svar_escape(code)
   return code:gsub("\"", "\\\""):gsub("\'", "\\\'"):gsub("`", "\\`")
end

local directives = {}

local function generate(ast, gencode)
   local lua_code = ""
   for i=1, #ast do
      local leaf = ast[i]
      if (leaf.type == "lua") then
         lua_code = lua_code .. leaf.code
      elseif (leaf.type == "directive") then
         local stargs = {}
         for i=1, #leaf.args do
            local arg = leaf.args[i]
            if (type(arg) == "string") then
               stargs[i] = "\""..lua_escape(arg).."\""
            elseif (type(arg) == "number") then
               stargs[i] = tostring(arg)
            elseif (type(arg) == "table" and arg.type=="lua_var") then
               stargs[i] = arg[1]
            end 
         end
         lua_code = lua_code .. "call_directive(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.name.."\","..table.concat(stargs, ",")..")"
      elseif (leaf.type == "envvar") then
         lua_code = lua_code .. "put_env(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.var.."\")"
      elseif (leaf.type == "code") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",\"" .. lua_escape(leaf.data) .. "\")"
      elseif (leaf.type == "lua_r") then
         lua_code = lua_code .. "put_code(\""..leaf.file..":"..tostring(leaf.line).."\",tostring("..leaf.code.."))"
      elseif (leaf.type == "shell") then
         lua_code = lua_code .. "put_shell_out(\""..leaf.file..":"..tostring(leaf.line).."\",\""..lua_escape(leaf.code).."\")"
      elseif (leaf.type == "shell_r") then
         lua_code = lua_code .. "put_svar(\""..leaf.file..":"..tostring(leaf.line).."\",\""..leaf.code.."\")"
      else
         io.stderr:write("ERROR: Internal catastrophic failure, unknown type "..leaf.type.."\n")
         os.exit(1)
      end
      lua_code = lua_code .. "\n"
   end
   local env = {code = ""}
   local function run_away_screaming(fpos, err)
      io.stdout:write("ERROR: "..fpos..": "..err.."\n")
      os.exit(1)
   end
   local function bitch(fpos, err)
      io.stdout:write("WARNING: "..fpos..": "..err.."\n")
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
   local function put_env(fpos, evar)
      local e = svar.get(evar)
      if not e then
         run_away_screaming(fpos, "Enviroment variable `"..evar.."' does not exist!")
      end
      env.code = env.code .. "\""..lua_escape(e).."\""
   end
   local function put_code(fpos, code)
      env.code = env.code .. code --not much that can fail here...
   end
   local function put_shell_out(fpos, code)
      local tname = os.tmpname()
      local f = os.tmpname()
      local fh = io.open(f, "w")
      fh:write(code)
      fh:close()
      os.execute("chmod +x "..f)
      local vars = svar.get_all()
      local vstr = ""
      for k, v in pairs(vars) do
         vstr = vstr .. k.."=".."\""..svar_escape(v).."\" "
      end
      dprint("Shell", vstr .. f.." "..tname)
      local h = io.popen(vstr .. f.." "..tname, "r")
      local output = h:read("*a"):gsub("\n$", "")
      local ok, sig, code = h:close()
      fh = io.open(tname, "r")
      local stderr = fh:read("*a"):gsub("\n$", "")
      fh:close()
      os.remove(f)
      os.remove(tname)
      if not ok then
         run_away_screaming(fpos, "Shell exit code "..code..", SIG_"..sig:upper().."\n"..stderr)
      elseif #stderr > 0 then
         bitch(fpos, stderr)
      end
      env.code = env.code .. output
   end
   local function put_svar(fpos, evar)
      local e = svar.get(evar)
      if not e then
         run_away_screaming(fpos, "Enviroment variable `"..evar.."' does not exist!")
      end
      env.code = env.code .. e
   end
   local fenv = {}
   for k, v in pairs(_G) do
      fenv[k] = v
   end
   if gencode then
      return lua_code
   end
   fenv._G = fenv
   fenv._ENV = fenv
   fenv.call_directive = call_directive
   fenv.put_code = put_code
   fenv.put_env = put_env
   fenv.put_svar = put_svar
   fenv.put_shell_out = put_shell_out
   fenv._GENERATOR=env
   local func = assert(load(lua_code, "=(generated code: "..ast.file..")", "t", fenv))
   func()
   return env.code
end