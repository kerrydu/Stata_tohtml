// ============================================================================
// Test script for the new ishere_translate function (regex-based)
// ============================================================================

clear all

// First, create a test do-file with ishere statements
tempname fh
local testfile "test_input.do"

file open `fh' using "`testfile'", write text replace
file write `fh' "// Test do-file with ishere statements" _n
file write `fh' "sysuse auto, clear" _n
file write `fh' "" _n
file write `fh' `"ishere display "Loading complete""' _n
file write `fh' "" _n
file write `fh' "summarize price mpg" _n
file write `fh' "" _n
file write `fh' "ishere checkpoint1" _n
file write `fh' "" _n
file write `fh' `"ishere display "Analysis done""' _n
file write `fh' "" _n
file write `fh' "ishere fig using results/plot1.png" _n
file write `fh' "" _n
file write `fh' "ishere tab using results/table1.html, width(80%) height(300px)" _n
file write `fh' "" _n
file write `fh' `"ishere display "Final result: " "123""' _n
file write `fh' "" _n
file write `fh' "regress price mpg weight" _n
file close `fh'

display as result "Created test file: `testfile'"
display ""

// Load the Mata functions
do ishere_translator.mata

display as result "=== Test 1: Process entire file ==="
display ""

mata:
// Read and process the file
results = process_file("test_input.do")

printf("Processing file line by line:\n")
printf("==============================\n\n")

for (i=1; i<=rows(results); i++) {
    printf("Line %2.0f: %s\n", i, results[i])
}
end

display ""
display as result "=== Test 2: Process individual lines ==="
display ""

mata:
// Test individual line processing
test_lines = (
    "ishere display " + char(34) + "Hello World" + char(34) \
    "ishere xxx" \
    "sysuse auto, clear" \
    "ishere display 123" \
    "ishere fig using myplot.png" \
    "ishere tab using mytable.html" \
    "ishere display " + char(34) + "Result: " + char(34) + " " + char(34) + "42" + char(34)
)

printf("\nTesting individual line translation:\n")
printf("====================================\n\n")

for (i=1; i<=rows(test_lines); i++) {
    input = test_lines[i]
    output = ishere_translate_line(input)
    
    printf("Input:  %s\n", input)
    printf("Output: %s\n", output)
    
    if (output == "") {
        printf("        (empty string)\n")
    }
    printf("\n")
}
end

display ""
display as result "=== Test 3: Display command parsing ==="
display ""

mata:
display_tests = (
    `"ishere display "Simple text""' \
    `"ishere display 42"' \
    `"ishere display "Part 1" " and " "Part 2""' \
    `"ishere display `"Compound quote"'"' \
    "ishere display 2+2"
)

printf("\nTesting display command parsing:\n")
printf("=================================\n\n")

for (i=1; i<=rows(display_tests); i++) {
    input = display_tests[i]
    output = ishere_translate_line(input)
    
    printf("Input:  %s\n", input)
    printf("Output: [%s]\n\n", output)
}
end

display ""
display as result "=== Test 4: Figure command parsing ==="
display ""

mata:
fig_tests = (
    "ishere fig using plot.png" \
    `"ishere figure using "results/chart.jpg""' \
    "ishere fig using graph.png, zoom(80%)" \
    "ishere fig using img.png, width(500) height(300)"
)

printf("\nTesting figure command parsing:\n")
printf("================================\n\n")

for (i=1; i<=rows(fig_tests); i++) {
    input = fig_tests[i]
    output = ishere_translate_line(input)
    
    printf("Input:  %s\n", input)
    printf("Output: %s\n\n", output)
}
end

display ""
display as result "=== Test 5: Table command parsing ==="
display ""

mata:
tab_tests = (
    "ishere tab using table.html" \
    `"ishere table using "results/data.html""' \
    "ishere tab using summary.html, width(90%) height(500px)"
)

printf("\nTesting table command parsing:\n")
printf("===============================\n\n")

for (i=1; i<=rows(tab_tests); i++) {
    input = tab_tests[i]
    output = ishere_translate_line(input)
    
    printf("Input:  %s\n", input)
    printf("Output: %s\n\n", output)
}
end

display ""
display as result "=== Test 6: Placeholder commands ==="
display ""

mata:
placeholder_tests = (
    "ishere marker1" \
    "ishere checkpoint" \
    "ishere" \
    "ishere xyz123"
)

printf("\nTesting placeholder commands (should return empty):\n")
printf("===================================================\n\n")

for (i=1; i<=rows(placeholder_tests); i++) {
    input = placeholder_tests[i]
    output = ishere_translate_line(input)
    
    printf("Input:  %s\n", input)
    printf("Output: [%s]\n", output)
    printf("Empty:  %s\n\n", (output == "" ? "YES" : "NO"))
}
end

display ""
display as result "=== Test 7: Mixed content ==="
display ""

mata:
// Simulate a real do-file with mixed content
mixed_content = (
    "clear all" \
    "sysuse auto" \
    "ishere display " + char(34) + "Data loaded" + char(34) \
    "summarize price" \
    "ishere marker1" \
    "regress price mpg" \
    "ishere display " + char(34) + "Regression complete" + char(34) \
    "ishere fig using results/residuals.png" \
    "predict resid, residuals"
)

results = ishere_translate(mixed_content)

printf("\nProcessing mixed content:\n")
printf("=========================\n\n")

for (i=1; i<=rows(mixed_content); i++) {
    is_changed = (mixed_content[i] != results[i])
    printf("[%s] %s\n", (is_changed ? "*" : " "), results[i])
    
    if (is_changed & results[i] == "") {
        printf("      (converted to empty placeholder)\n")
    }
}

printf("\n* = line was processed by ishere_translate\n")
end

display ""
display as result "All tests completed!"

// Clean up
capture erase "test_input.do"
