svar = {}

do
	local stdlib = require("posix.stdlib")

	function svar.get(var)
		return os.getenv(var)
	end

	function svar.set(var, val)
		return stdlib.setenv(var, val and tostring(val) or nil)
	end
end