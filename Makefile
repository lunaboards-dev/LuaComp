ifeq ($(OS),Windows_NT)
	# If you're using Windows, change the path to wherever you put LuaComp in.
	COMMAND = lua53 "./luacomp.lua"
	# COMMAND = lua53 "C:/Standalone Programs/luacomp.lua"
else
	
	COMMAND = luacomp
endif

build:
	@echo Building LuaComp...
	@${COMMAND} ./src/application.lua -O ./luacomp.lua

clean:
	ifeq ($(OS),Windows_NT)
		rmdir build /s /q
	else
		rm -rf build
	endif
