# ishere_translate - Mata Function for Parsing and Executing ishere Statements

## Overview

This package provides a Mata function `ishere_translate()` that parses and executes `ishere` statements, returning their output as a string. This is particularly useful for automated report generation and programmatic handling of `ishere` commands.

## Files Included

1. **ishere_translator.mata** - Main Mata functions
2. **ishere_exec.ado** - Stata wrapper command
3. **ishere_translator.sthlp** - Help documentation
4. **test_ishere_translator.do** - Test script with examples

## Quick Start

### Method 1: Using Mata directly

```stata
// Load the Mata functions
do ishere_translator.mata

// Use the function
mata:
result = ishere_translate("ishere display " + char(34) + "Hello World" + char(34))
printf("Output: %s\n", result)
end
```

### Method 2: Using Stata command wrapper

```stata
// The wrapper automatically loads the Mata functions
ishere_exec ishere display "Hello World"
return list
```

## Function Behavior

The `ishere_translate()` function handles different types of `ishere` statements:

### 1. Display Commands
Returns the displayed text:

```stata
mata:
result = ishere_translate("ishere display " + char(34) + "xxx" + char(34))
// Returns: "xxx"
end
```

### 2. Placeholder Commands
Returns empty string:

```stata
mata:
result = ishere_translate("ishere xxx")
// Returns: ""
end
```

### 3. Figure/Table Commands
Returns the markdown output:

```stata
mata:
result = ishere_translate("ishere fig using myplot.png")
// Returns: markdown code for embedding the figure
end
```

## Examples

### Example 1: Simple display
```stata
mata:
result = ishere_translate("display 123")
result  // Shows: 123
end
```

### Example 2: Display with expression
```stata
mata:
result = ishere_translate("display 2+2")
result  // Shows: 4
end
```

### Example 3: Empty result for placeholder
```stata
mata:
result = ishere_translate("ishere myplaceholder")
result  // Shows: (empty string)
result == ""  // Returns: 1 (true)
end
```

### Example 4: Programmatic usage
```stata
mata:
commands = ("display 1" \ "display 2" \ "ishere xxx" \ "display 3")
for (i=1; i<=rows(commands); i++) {
    result = ishere_translate(commands[i])
    printf("Command %f result: [%s]\n", i, result)
}
end
```

## Testing

Run the test script to see all examples in action:

```stata
do test_ishere_translator.do
```

This will run 7 different test cases demonstrating various uses of the function.

## Function Signature

```mata
string scalar ishere_translate(string scalar cmd)
```

**Parameters:**
- `cmd`: String containing the ishere command to execute

**Returns:**
- String containing the command output
- Empty string "" if the command produces no output

## Implementation Details

The function works by:

1. Parsing the input command to identify the command type
2. For `display` commands: executing them and capturing the output using temporary log files
3. For `fig`/`table` commands: executing the ishere command and capturing markdown output
4. For other commands: returning empty string (acting as placeholders)

## Requirements

- Stata version 14 or higher
- The `ishere.ado` command should be installed for full functionality

## Author

Stata to HTML integration team, 2026
