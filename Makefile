ifeq ($(OS),Windows_NT)
# If you're using Windows, change the path to wherever you put LuaComp in.
COMMAND = lua53 "./luacomp.lua"
# COMMAND = lua53 "C:/Standalone Programs/luacomp.lua"
else
COMMAND = luacomp
endif

build:
	@echo Building LuaComp...
	@${COMMAND} ./src/init.lua -O ./luacomp.lua

install:
ifeq ($(OS),Windows_NT)
	@echo Installing is not supported on Windows
else
	@echo Installing LuaComp...
	@echo "#!/usr/bin/env lua5.3" | cat - ./luacomp.lua > ~/bin/luacomp
	@chmod +x ~/bin/luacomp
endif

clean:
ifeq ($(OS),Windows_NT)
	@rmdir build /s /q
else
	@rm -rf build
endif
