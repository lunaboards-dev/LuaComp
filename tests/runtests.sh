for test in $(find -name "*.lua"); do
	echo "Running test $test"
	luacomp $test > $test.out
	echo "=============================================================="
done