-- raw evar
print("your shell is $[{SHELL}]")
-- evar string
print("your shell is "..$(SHELL))
-- cat
$[[cat nopreproc.lua]]
