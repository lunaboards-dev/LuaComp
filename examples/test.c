#include <stdio.h>
/* I really don't know why you'd do this. */

@[[function my_macro(a, b)]]
	printf("Good morning, @[{a}]. Your lucky number is @[{b}].");
@[[end]]

int main() {
	@[[my_macro("user", 7)]]
	@[[my_macro("Steve", 24)]]
	@[[my_macro("Mr. Bones", 666)]]
	@[[my_macro("mother", -1)]]
	@[[my_macro(os.getenv("USER"), os.getenv("UID"))]]
	return 0;
}