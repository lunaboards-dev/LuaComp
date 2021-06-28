local luaexec = {
	"5.4",
	"5.3",
	"5.2",
	"5.1",
	"jit"
}

os.execute("rm -rf build")
os.execute("mkdir build")
for i=1, #luaexec do
	os.execute("luacomp -xlua"..luaexec[i].." -mluamin -O build/luacomp-"..luaexec[i].." src/init.lua")
	--os.execute("luacomp -xlua"..luaexec[i].." -mnone -O build/luacomp-static-"..luaexec[i].." src/staticinit.lua")
	os.execute("chmod +x build/luacomp-"..luaexec[i])
	--os.execute("chmod +x build/luacomp-static-"..luaexec[i])
end

os.execute("LIBLUACOMP=y luacomp -O build/libluacomp.lua src/libluacomp.lua")

os.execute("cp -v build/luacomp-".._VERSION:sub(5).." luacomp")