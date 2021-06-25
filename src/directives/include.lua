function directives.include(env, file)
	local sr, err = stat.stat(file)
	if not sr then return false, err end
	--[[local f = io.open(file, "r")
	local fast = mkast(f, file)
	fast.file = file
	local code = generate(fast)
	env.code = env.code .. code .. "\n"]]
	env.code = env.code .. luacomp.process_file(file, file) .. "\n"
	return true
end