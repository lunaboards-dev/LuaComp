@[[function my_macro(a, b)]]
print("Hello, @[{a}]. Your lucky number is @[{b}].")
@[[end]]

@[[my_macro("world", 7)]]
@[[my_macro("user", 42)]]
@[[my_macro("Earth", 0)]]
@[[my_macro("Satna", 666)]]