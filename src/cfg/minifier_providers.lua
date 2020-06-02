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

local postproc_paths = {
	"/usr/share/luacomp/postproc",
	os.getenv("HOME").."/.local/share/luacomp/postproc"
}

local providers = {}

function providers.luamin(cin)
	local fn = os.tmpname()
--	io.stderr:write("DEBUG: ",fn,"\n")
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	-- I have no idea why luamin keeps throwing errors in my buildscript
	-- if I make this `luamin -f <tmpfile>` and I have no fucking clue as
	-- to why this fixes it, but I guess I shouldn't complain. But I will
	-- anyways. What the actual fuck is this and what the actual fuck was
	-- that error?
	local lmh = io.popen("cat \""..fn.."\" | luamin -c", "r")
--	io.stderr:write("DEBUG: ", "luamin -f "..fn.." 2>&1", "\n")
	local dat = lmh:read("*a")
	local stat, _, code = lmh:close()
	os.remove(fn)
	if (code ~= 0) then
		return false, dat
	end
	return dat
end

function providers.bython(cin)
	local fn = os.tmpname()
	local fo = os.tmpname()
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	local lmh = io.popen("bython -c "..fn.." "..fo.." 2>&1", "r")
	local out = lmh:read("*a")
	local stat, _, code = lmh:close()
	os.remove(fn)
	if (code ~= 0) then
		os.remove(fo)
		return false, out
	end
	fh = io.open(fo, "r")
	local dat = fh:read("*a")
	fh:close()
	os.remove(fo)
	return dat
end

function providers.bython2(cin)
	local fn = os.tmpname()
	local fo = os.tmpname()
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	local lmh = io.popen("bython -c2 "..fn.." "..fo.." 2>&1", "r")
	local out = lmh:read("*a")
	local stat, _, code = lmh:close()
	os.remove(fn)
	if (code ~= 0) then
		os.remove(fo)
		return false, out
	end
	fh = io.open(fo, "r")
	local dat = fh:read("*a")
	fh:close()
	os.remove(fo)
	return dat
end

function providers.uglify(cin)
	local fn = os.tmpname()
	local fh = io.open(fn, "w")
	fh:write(cin)
	fh:close()
	local lmh = io.popen("uglifyjs --compress --mangle -- "..fn.." 2>&1", "r")
	local dat = lmh:read("*a")
	local stat, _, code = lmh:close()
	os.remove(fn)
	if (code ~= 0) then
		return false, dat
	end
	return dat
end

function providers.none(cin)
	return cin
end

setmetatable(providers, {__index=function(t, i)
	for i=1, #postproc_paths do
		if (os.execute("stat "..postproc_paths[i].."/"..i..".lua 1>/dev/null 2>&1")) then
			providers[i] = loadfile(postproc_paths[i].."/"..i..".lua")()
			return providers[i]
		end
	end
end})

local function preload_providers()
	--Do this in the best way possible
	for i=1, #postproc_paths do
		if (os.execute("stat "..postproc_paths[i].."1>/dev/null 2>&1")) then
			local fh = io.popen("ls "..postproc_paths[i], "r")
			for line in fh:lines() do
				if (line:match("%.lua$")) then
					providers[line:sub(1, #line-4)] = loadfile(postproc_paths[i].."/"..line)()
				end
			end
		end
	end
end