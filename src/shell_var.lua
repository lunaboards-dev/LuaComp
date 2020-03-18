svar = {}

local svars = {}

function svar.get(var)
	return svars[var] or os.getenv(var)
end

function svar.set(var, val)
	svars[var] = tostring(val)
end

function svar.get_all()
	return svars
end