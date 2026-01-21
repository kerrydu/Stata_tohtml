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
file write `fh' `" ishere   display   ## Data Overview"' _n
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

// ============================================================================
// Step 4: Save the converted output
// ============================================================================

display as result "Step 4: Saving converted output..."

mata:
// Save to output file
output_file = "sample_analysis_converted.md"
fh = fopen(output_file, "w")

for (i=1; i<=rows(output_lines); i++) {
    fput(fh, output_lines[i])
}

fclose(fh)

printf("  Saved to: %s\n", output_file)
end

display ""

// ============================================================================
// Step 5: Display the converted content
// ============================================================================

display as result "Step 5: Displaying converted content..."
display ""
display "{hline 70}"

mata:
for (i=1; i<=rows(output_lines); i++) {
    printf("%s\n", output_lines[i])
}
end

display "{hline 70}"
display ""

// ============================================================================
// Step 6: Demonstrate batch processing
// ============================================================================

display as result "Step 6: Batch processing example..."
display ""

mata:
// Example: Extract only ishere outputs
printf("Extracted ishere outputs only:\n")
printf("==============================\n\n")

for (i=1; i<=rows(input_lines); i++) {
    line = strtrim(input_lines[i])
    if (substr(line, 1, 6) == "ishere") {
        output = output_lines[i]
        if (output != "") {
            printf("[Line %2.0f] %s\n", i, output)
        }
        else {
            printf("[Line %2.0f] (placeholder)\n", i)
        }
    }
}
end

display ""

// ============================================================================
// Step 7: Create a conversion function for general use
// ============================================================================

display as result "Step 7: Defining reusable conversion function..."
display ""

mata:
// Reusable function to convert do-files
void convert_dofile_to_markdown(string scalar infile, string scalar outfile) {
    string colvector input_lines, output_lines
    real scalar fh, i, n_converted
    
    // Check input file exists
    if (!fileexists(infile)) {
        errprintf("Input file not found: %s\n", infile)
        return
    }
    
    // Read and convert
    input_lines = read_file_lines(infile)
    output_lines = ishere_translate(input_lines)
    
    // Write output
    fh = fopen(outfile, "w")
    for (i=1; i<=rows(output_lines); i++) {
        fput(fh, output_lines[i])
    }
    fclose(fh)
    
    // Report
    n_converted = 0
    for (i=1; i<=rows(input_lines); i++) {
        if (input_lines[i] != output_lines[i]) n_converted++
    }
    
    printf("Conversion complete:\n")
    printf("  Input:  %s (%f lines)\n", infile, rows(input_lines))
    printf("  Output: %s\n", outfile)
    printf("  Converted: %f ishere statements\n", n_converted)
}

// Test the function
printf("Testing conversion function:\n")
convert_dofile_to_markdown("sample_analysis.do", "output_test.md")
end

display ""

// ============================================================================
// Step 8: Advanced example - selective output
// ============================================================================

display as result "Step 8: Advanced example - selective extraction..."
display ""

mata:
// Extract only markdown headers (from display commands)
printf("Markdown headers extracted:\n")
printf("===========================\n\n")

for (i=1; i<=rows(input_lines); i++) {
    line = strtrim(input_lines[i])
    if (regexm(line, "^ishere display")) {
        output = output_lines[i]
        if (regexm(output, "^#")) {
            printf("%s\n", output)
        }
    }
}

printf("\n")

// Extract only figure/table references
printf("Figure/Table references:\n")
printf("========================\n\n")

for (i=1; i<=rows(input_lines); i++) {
    line = strtrim(input_lines[i])
    if (regexm(line, "^ishere (fig|figure|tab|table)")) {
        output = output_lines[i]
        if (output != "") {
            printf("%s\n\n", output)
        }
    }
}
end

display ""
display as result "=== All examples completed! ==="
display ""

// Show files created
display "Files created:"
display "  - sample_analysis.do (input)"
display "  - sample_analysis_converted.md (output)"
display "  - output_test.md (test output)"
display ""

// Clean up option
display "To clean up test files, run:"
display `"  erase sample_analysis.do"'
display `"  erase sample_analysis_converted.md"'
display `"  erase output_test.md"'
