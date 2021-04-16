function directives.include(env, file)
	local f = io.open(file, "r")
	if f == nil then
		return false, "File `"..file.."' does not exist!"
	end
	local fast = mkast(f, file)
	fast.file = file
	local code = generate(fast)
	env.code = env.code .. code .. "\n"
	return true
end