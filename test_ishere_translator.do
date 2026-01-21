// Test script for ishere_translate Mata function
// This script demonstrates how to use the ishere_translate() function

clear all

// Load the Mata function
do ishere_translator.mata

// Test 1: ishere display "xxx" should return "xxx"
mata:
result1 = ishere_translate("ishere display " + char(34) + "Hello World" + char(34))
printf("Test 1: ishere display " + char(34) + "Hello World" + char(34) + "\n")
printf("Result: [%s]\n\n", result1)
end

// Test 2: ishere display with number
mata:
result2 = ishere_translate("display 123")
printf("Test 2: display 123\n")
printf("Result: [%s]\n\n", result2)
end

// Test 3: ishere display with expression
mata:
result3 = ishere_translate("ishere display 2+2")
printf("Test 3: ishere display 2+2\n")
printf("Result: [%s]\n\n", result3)
end

// Test 4: ishere with just a word (no display) should return empty
mata:
result4 = ishere_translate("ishere xxx")
printf("Test 4: ishere xxx\n")
printf("Result: [%s]\n", result4)
printf("Is empty: %s\n\n", (result4 == "" ? "Yes" : "No"))
end

// Test 5: ishere with no command should return empty
mata:
result5 = ishere_translate("ishere")
printf("Test 5: ishere (empty)\n")
printf("Result: [%s]\n", result5)
printf("Is empty: %s\n\n", (result5 == "" ? "Yes" : "No"))
end

// Test 6: display with string variable
mata:
st_local("test_var", "This is a test")
end
mata:
result6 = ishere_translate("display " + char(34) + st_local("test_var") + char(34))
printf("Test 6: display with local variable\n")
printf("Result: [%s]\n\n", result6)
end

// Test 7: Multiple display strings
mata:
result7 = ishere_translate("display " + char(34) + "Line 1" + char(34) + " _n " + char(34) + "Line 2" + char(34))
printf("Test 7: display with multiple strings\n")
printf("Result: [%s]\n\n", result7)
end

display as result _newline "All tests completed!"
