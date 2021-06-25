--[[
	cfg/minifier_providers.lua - Provides minifier providers.
]]

-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
		if stat.stat(postproc_paths[i].."/"..i..".lua") then
			providers[i] = loadfile(postproc_paths[i].."/"..i..".lua")()
			return providers[i]
		end
	end
end})

local function preload_providers()
	--Do this in the best way possible
	for i=1, #postproc_paths do
		if stat.stat(postproc_paths[i]) then
			for ent in dirent.files(postproc_paths[i]) do
				if ent:match("%.lua$") then
					providers[ent:sub(1, #ent-4)] = loadfile(postproc_paths[i].."/"..ent)()
				end
			end
		end
	end
end