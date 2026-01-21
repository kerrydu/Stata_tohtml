// ============================================================================
// ishere_translator_example.do
// Practical example showing how to use ishere_translate() in real scenarios
// ============================================================================

clear all

// Load the Mata functions
do ishere_translator.mata

// ============================================================================
// Scenario 1: Parsing a do-file with ishere statements
// ============================================================================

display as result _newline "=== Scenario 1: Processing ishere statements from code ==="

// Simulate reading lines from a do-file
mata:
// Array of code lines that might appear in a do-file
code_lines = (
    "sysuse auto, clear" \
    "ishere display " + char(34) + "Data loaded successfully" + char(34) \
    "summarize price" \
    "ishere checkpoint1" \
    "ishere display " + char(34) + "Running regression..." + char(34) \
    "regress price mpg weight" \
    "ishere display " + char(34) + "Analysis complete" + char(34)
)

printf("\nProcessing code lines:\n")
printf("---------------------\n")

for (i=1; i<=rows(code_lines); i++) {
    line = code_lines[i]
    
    // Check if line starts with "ishere"
    if (substr(strtrim(line), 1, 6) == "ishere") {
        result = ishere_translate(line)
        
        if (result != "") {
            printf("Line %f: %s\n", i, line)
            printf("  -> Output: [%s]\n", result)
        }
        else {
            printf("Line %f: %s\n", i, line)
            printf("  -> Output: [empty - placeholder]\n")
        }
    }
}
end

// ============================================================================
// Scenario 2: Building a dynamic report
// ============================================================================

display as result _newline "=== Scenario 2: Building a dynamic report ==="

sysuse auto, clear

mata:
// Report sections with ishere statements
report_sections = (
    "display " + char(34) + "# Auto Dataset Analysis" + char(34) \
    "display " + char(34) + "Dataset contains " + char(34) + " + strofreal(st_nobs()) + " + char(34) + " observations" + char(34) \
    "display " + char(34) + "## Summary Statistics" + char(34)
)

printf("\nGenerating report content:\n")
printf("-------------------------\n")

for (i=1; i<=rows(report_sections); i++) {
    result = ishere_translate(report_sections[i])
    printf("%s\n", result)
}
end

// ============================================================================
// Scenario 3: Conditional output based on ishere result
// ============================================================================

display as result _newline "=== Scenario 3: Conditional processing ==="

mata:
// Test different commands and take action based on output
test_commands = (
    "display 1+1" \
    "ishere marker1" \
    "display " + char(34) + "Active" + char(34) \
    "ishere marker2"
)

printf("\nProcessing commands conditionally:\n")
printf("----------------------------------\n")

for (i=1; i<=rows(test_commands); i++) {
    cmd = test_commands[i]
    result = ishere_translate(cmd)
    
    if (result != "") {
        printf("Command: %s\n", cmd)
        printf("  -> Has output: YES [%s]\n", result)
        printf("  -> Action: Include in report\n\n")
    }
    else {
        printf("Command: %s\n", cmd)
        printf("  -> Has output: NO\n")
        printf("  -> Action: Skip or use as marker\n\n")
    }
}
end

// ============================================================================
// Scenario 4: Using results in Stata
// ============================================================================

display as result _newline "=== Scenario 4: Using results in Stata code ==="

// Use the wrapper command
ishere_exec display "Starting analysis..."
local msg1 = r(result)
display "Captured message 1: " `"`msg1'"'

ishere_exec ishere placeholder
local msg2 = r(result)
display "Captured message 2: " `"`msg2'"' " (empty = " (`"`msg2'"'=="") ")"

ishere_exec display 42
local answer = r(result)
display "The answer is: `answer'"

// ============================================================================
// Scenario 5: Batch processing
// ============================================================================

display as result _newline "=== Scenario 5: Batch processing multiple ishere statements ==="

mata:
// Function to process a batch of ishere statements
void process_ishere_batch(string colvector statements) {
    real scalar i
    string scalar cmd, result
    
    printf("\nBatch Processing Results:\n")
    printf("========================\n")
    
    for (i=1; i<=rows(statements); i++) {
        cmd = statements[i]
        result = ishere_translate(cmd)
        
        printf("\n[%f] %s\n", i, cmd)
        if (result != "") {
            printf("    Output: %s\n", result)
        } else {
            printf("    Output: (none)\n")
        }
    }
}

// Test batch processing
batch = (
    "display " + char(34) + "Step 1: Initialize" + char(34) \
    "ishere step1_marker" \
    "display " + char(34) + "Step 2: Process" + char(34) \
    "display " + char(34) + "Result: " + char(34) + " + strofreal(100) \
    "ishere step2_marker"
)

process_ishere_batch(batch)
end

display as result _newline "=== All scenarios completed! ==="
