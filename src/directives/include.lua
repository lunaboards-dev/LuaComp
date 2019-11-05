function directives.include(env, file)
	if (not os.execute("stat "..file..">/dev/null")) then
		return false, "File `"..file.."' does not exist!"
	end
	local f = io.open(file, "r")
	local fast = mkast(f, file)
	local code = generate(fast)
	env.code = env.code .. "\n" .. code .. "\n"
	return true
end