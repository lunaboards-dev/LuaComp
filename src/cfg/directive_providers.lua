local directive_paths = {}
if os.getenv("OS") == "Windows_NT" then
	-- table.insert(directive_paths, os.getenv("appdata") .. "/luacomp/directives")
else
	table.insert(directive_paths, "/usr/share/luacomp/directives")
	table.insert(directive_paths, os.getenv("HOME") .. "/.local/share/luacomp/directives")
end