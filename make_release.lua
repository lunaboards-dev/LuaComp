print("INFO: Static builds may not be usable due to unfinished strings bug. Normal builds require argparse.")
local luaToUse = "lua53"

-- Clear the build directory.
if os.getenv("OS") == "Windows_NT" then
	os.execute("rmdir build /s /q")
	os.execute("mkdir build")
	os.execute("mkdir build\\linux")
else
	os.execute("rm -rf build")
	os.execute("mkdir build")
	os.execute("mkdir build/inux")
end

local luaexec = {
	"5.4",
	"5.3",
	"5.2",
	"5.1",
	"jit"
}
local luaCompPath = ({...})[1] or ""
local isLuaCompInstalled = true

-- Check for LuaComp installation.
if os.getenv("OS") == "Windows_NT" then
	if luaCompPath == "" then
		print("LuaComp path not set. This is required for Windows")
		print("To set the path to LuaComp, supply it as an argument to this program.")
		os.exit()
	end
	isLuaCompInstalled = false
else
	if (not io.open("/bin/luacomp", "r")) and luaCompPath == "" then
		print("No existing installation of LuaComp found and LuaComp path is not set. Either make sure you have LuaComp installed or set the LuaComp path.")
		print("To set the path to LuaComp, supply it as an argument to this program.")
		os.exit()
	elseif not io.open("/bin/luacomp", "r") then
		isLuaCompInstalled = false
	end
end

-- Build Windows versions
if os.getenv("OS") == "Windows_NT" then
	os.execute(luaToUse .. " " .. luaCompPath .. " ./src/init.lua -O ./build/luacomp.lua")
	os.execute(luaToUse .. " " .. luaCompPath .. " ./src/staticinit.lua -O ./build/luacomp-static.lua")
else
	if isLuaCompInstalled == true then
		os.execute("luacomp ./src/init.lua -O ./build/luacomp.lua")
		os.execute("luacomp ./src/staticinit.lua -O ./build/luacomp-static.lua")
	else
		os.execute(luaToUse .. " " .. luaCompPath .. " ./src/init.lua -O ./build/luacomp.lua")
		os.execute(luaToUse .. " " .. luaCompPath .. " ./src/staticinit.lua -O ./build/luacomp-static.lua")
	end
end

-- Build Linux versions that are directly executable.
for _,version in ipairs(luaexec) do
	print("Making release for Lua " .. version)
	if os.getenv("OS") == "Windows_NT" then
		os.execute(luaToUse .. " " .. luaCompPath .. " ./src/init.lua -O ./build/linux/luacomp-" .. version .. " --executable " .. version)
		os.execute(luaToUse .. " " .. luaCompPath .. " ./src/staticinit.lua -O ./build/linux/luacomp-static-" .. version .. " --executable " .. version)
	else
		if isLuaCompInstalled == true then
			os.execute("luacomp ./src/init.lua -O ./build/linux/luacomp-" .. version .. " --executable " .. version)
			os.execute("luacomp ./src/staticinit.lua -O ./build/linux/luacomp-static-" .. version .. " --executable " .. version)
		else
			os.execute(luaToUse .. " " .. luaCompPath .. " ./src/init.lua -O ./build/linux/luacomp-" .. version .. " --executable " .. version)
			os.execute(luaToUse .. " " .. luaCompPath .. " ./src/staticinit.lua -O ./build/linux/luacomp-static-" .. version .. " --executable " .. version)
		end
	end
end

-- Original script for reference.

-- os.execute("rm -rf build")
-- os.execute("mkdir build")
-- for i=1, #luaexec do
-- 	os.execute("luacomp -xlua"..luaexec[i].." -mluamin -O build/luacomp-"..luaexec[i].." src/init.lua")
-- 	os.execute("luacomp -xlua"..luaexec[i].." -mnone -O build/luacomp-static-"..luaexec[i].." src/staticinit.lua")
-- 	os.execute("chmod +x build/luacomp-"..luaexec[i])
-- 	os.execute("chmod +x build/luacomp-static-"..luaexec[i])
-- end

-- os.execute("cp -v build/luacomp-".._VERSION:sub(5).." luacomp")