function directives.define(env, evar, val)
	os.setenv(evar, val)
	return true
end