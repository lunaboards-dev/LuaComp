function directives.include(env, file)
	if (not os.execute("stat "..file..">/dev/null")) then
		return false, "File `"..file.."' does not exist!"
	end
	--[[local f = io.open(file, "r")
	local fast = mkast(f, file)
	fast.file = file
	local code = generate(fast)
	env.code = env.code .. code .. "\n"]]
	env.code = env.code .. luacomp.process_file(file, file) .. "\n"
	return true
end