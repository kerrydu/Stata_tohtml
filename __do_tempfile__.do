// ============================================================================
// example_usage.do
// Practical example: Converting a Stata do-file with ishere statements
// ============================================================================

clear all

// ============================================================================
// Step 1: Create a sample analysis do-file with ishere statements
// ============================================================================

display as result "Step 1: Creating sample analysis file..."

tempname fh
local inputfile "sample_analysis.do"

file open `fh' using "`inputfile'", write text replace
file write `fh' "// Sample Data Analysis" _n
file write `fh' "// This file demonstrates ishere usage" _n
file write `fh' "" _n
file write `fh' "clear all" _n
file write `fh' "sysuse auto" _n
file write `fh' "" _n
file write `fh' `" ishere  # Auto Dataset Analysis"' _n
file write `fh' "" _n
file write `fh' `" ishere   ## Data Overview"' _n
file write `fh' "" _n
file write `fh' "describe" _n
file write `fh' "summarize" _n
file write `fh' "" _n
file write `fh' "ishere marker_descriptives" _n
file write `fh' "" _n
file write `fh' `"ishere display "## Visualizations""' _n
file write `fh' "" _n
file write `fh' "graph bar price, over(foreign)" _n
file write `fh' `"graph export "results/price_by_origin.png", replace"' _n
file write `fh' "" _n
file write `fh' "ishere fig using results/price_by_origin.png, zoom(80%)" _n
file write `fh' "" _n
file write `fh' `"ishere display "## Regression Analysis""' _n
file write `fh' "" _n
file write `fh' "regress price mpg weight foreign" _n
file write `fh' "" _n
file write `fh' "ishere tab using results/regression_table.html" _n
file write `fh' "" _n
file write `fh' `"ishere display "Analysis complete.""' _n
file close `fh'

display "  Created: `inputfile'"
display ""

// ============================================================================
// Step 2: Load the translator functions
// ============================================================================

display as result "Step 2: Loading ishere_translator functions..."
do C:\Users\kerry\Downloads\Documents\Stata_tohtml\ishere_translator.mata
display "  Functions loaded."
display ""

// ============================================================================
// Step 3: Process the file and show results
// ============================================================================

display as result "Step 3: Processing the file..."
display ""

mata:
// Read and process the file
input_lines = read_file_lines("sample_analysis.do")
output_lines = ishere_translate(input_lines)

printf("File processing results:\n")
printf("========================\n\n")
printf("Total lines: %f\n", rows(input_lines))
printf("\n")

// Count how many lines were transformed
transformed = 0
for (i=1; i<=rows(input_lines); i++) {
    if (input_lines[i] != output_lines[i]) {
        transformed++
    }
}

printf("Transformed lines: %f\n", transformed)
printf("\n")

// Show side-by-side comparison of changed lines
printf("Line-by-line transformation:\n")
printf("============================\n\n")

for (i=1; i<=rows(input_lines); i++) {
    if (input_lines[i] != output_lines[i]) {
        printf("Line %2.0f:\n", i)
        printf("  Input:  %s\n", input_lines[i])
        printf("  Output: %s\n", output_lines[i])
        printf("\n")
    }
}
end