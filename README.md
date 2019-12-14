# LuaComp
A general purpose preprocessor and postprocessor written in Lua.

## Building
See manual/README.md

## How-To

### Merging source files
```lua
-- myfile.lua
local my_lib = {}

function my_lib.hello_world()
  print("Hello, world!")
end
```

```lua
-- main.lua
--#include "my_file.lua"
my_lib.hello_world()
```

### Getting enviroment variables
```lua
print("This was compiled in the shell "..$(SHELL))
```

### Macros
```lua
@[[function my_macro(a, b)]]
print("Hello, @[{a}]. Your lucky number is @[{b}].")
@[[end]]

@[[my_macro("world", 7)]]
@[[my_macro("user", 42)]]
@[[my_macro("Earth", 0)]]
@[[my_macro("Satna", 666)]]
```
