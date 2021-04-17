# Building

## Luapreproc
```sh
git clone https://github.com/Adorable-Catgirl/LuaComp.git
cd LuaComp
luapreproc src/init.lua /tmp/luacomp.part
echo "#!/usr/bin/env lua5.3" | cat - /tmp/luacomp.part > ~/bin/luacomp
chmod +x ~/bin/luacomp
```

## LuaComp
```sh
git clone https://github.com/Adorable-Catgirl/LuaComp.git
cd LuaComp
luacomp -xlua5.3 -mluamin -O ~/bin/luacomp src/init.lua
chmod +x ~/bin/luacomp
```

## Make
```sh
make
# Optional install(*nix only)
make install
```

## By hand
Ha, no.

# Usage
`luacomp -h` outputs:
```
Usage: /tmp/luacomp [-h] [-O <output>] [-m <minifier>]
       [--generator-code] [--verbose] [--post-processors]
       [--directives] [-v] <input> [-x [<executable>]]

LuaComp v1.2.0
A preprocessor+postprocessor written in Lua.

Arguments:
   input                 Input file (- for STDIN)

Options:
   -h, --help            Show this help message and exit.
         -O <output>,    Output file. (- for STDOUT) (default: -)
   --output <output>
           -m <minifier>,
   --minifier <minifier>
                         Sets the minifier (default: none)
             -x [<executable>],
   --executable [<executable>]
                         Makes the script an executable (default: current lua version)
   --generator-code      Outputs only the code from the generator.
   --verbose             Verbose output. (Debugging)
   --post-processors     Lists postprocessors
   --directives          Lists directives
   -v, --version         Prints the version and exits
```
# Directives
LuaComp currently ships with four built-in directives. More directives can be installed at these directories:

Linux: `/usr/share/luacomp/directives` and `~/.local/share/luacomp/directives`.

Windows: `%appdata%\luacomp\directives`

## include
Usage: `--#include "path"`
Include tells the preprocessor to include the file specified. The file included will also be preprocessed.

## define
Usage `--#define "var" "value"`
Defines the env var for this session.

## error
Usage `--#error "text"`
Throws an error and stops the preprocessor.

## loadmod
**Note**: Depreciated, use the directive dirs.
Usage `--#loadmod "lua_file.lua"`
Loads a directive module. Don't use this. I just don't want to have to bump the major version number.

# Postprocessors
LuaComp currently ships with built-in support for three postprocessors. More postprocessors can be installed at these directories:

Linux: `/usr/share/luacomp/postproc` and `~/.local/share/luacomp/postproc`

Windows: `%appdata%\luacomp\postproc`

## luamin
Language: Lua 5.1 to 5.3<br>
Minifies Lua.

## uglify
Language: JavaScript<br>
Minifies JS. Options are `--compress --mangle`.

## bython(2)
Language: Bython (Python 3.x and 2.x)<br>
Turns Bython into Python.

# Syntax
The syntax was made for Lua, but it works well enough for some other languages.

## Directives
Syntax: `--#directive "arguments"`

## Lua code
Syntax: `@[[ code ]]`
Note that this can be used for macros.
See examples/macro.lua.

## Lua variable
Syntax: `@[{ variable }]`
Puts the value of the variable in the code

## Quoted shell variables
Syntax: `$(var)`
Puts the value of the variable in the code, quoted.

## Unquoted shell variables
Syntax: `$[{var}]`
Puts the value of the variable in the code, not quoted.

## Shell output
Syntax: `$[[code]]`
Puts the stdout of the script in the code. Note that you can't set variables from the shell script.

# Debugging

## Generator code
To output the code the generator executes, add the `--generator-code` flag.

## Debug messages
To output debug messages, add the `--verbose` flag.