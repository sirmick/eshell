# Bash Interpreter CLI Examples

This folder contains comprehensive example bash scripts that demonstrate all the parsing features of the Bash Interpreter. Each script tests specific aspects of the parser.

## Usage

```bash
# Test with pretty_print walker (default)
mix run lib/bash_cli.ex examples/bash_files/basic_commands.sh

# Test with inspect walker for detailed AST structure
mix run lib/bash_cli.ex examples/bash_files/basic_commands.sh inspect

# Test JSON output for debugging
mix run lib/bash_cli.ex examples/bash_files/basic_commands.sh json

# Test round-trip conversion
mix run lib/bash_cli.ex examples/bash_files/basic_commands.sh round_trip
```

## Available Example Scripts

### 1. basic_commands.sh
**Features**: Simple commands, semicolons, newlines, mixed separators
- Commands with and without arguments
- Command chains using semicolons
- Mixed newline and semicolon separators
- Commands with options and redirections

### 2. if_then_else.sh  
**Features**: Conditional (if/then/else) statements
- Basic if-then construct
- Two-way conditional branching (if-then-else)
- File system conditions (existence, permissions)
- Numeric comparisons
- Complex boolean logic with AND/OR
- Nested conditionals
- String comparisons and pattern matching

### 3. redirections_pipelines.sh
**Features**: Input/output redirections and complex pipelines
- Basic redirects (`>`, `>>`, `<`)
- Multiple redirections per command
- Multi-stage pipelines
- Real-world data processing pipelines
- Log analysis pipelines
- Mixed redirections and pipelines
- Error handling with redirects

### 4. loops.sh
**Features**: For loops, while loops, nested loops
- Basic for loops with lists
- Command substitution in loops
- C-style for loops
- While loops with conditions
- Nested loops within each other
- Loop control structures
- Interactive loops

### 5. complex_real_world.sh
**Features**: Real-world deployment script with mixed features
- Complex conditional logic
- Multiple control structures nested
- Real-world deployment scenarios
- Error handling patterns
- Configuration management
- File operations and system checks
- Logging and reporting
- Batch processing patterns

## Testing Individual Files

```bash
# Test basic command parsing
mix run lib/bash_cli.ex examples/bash_files/basic_commands.sh

# Test conditionals with detailed inspection
mix run lib/bash_cli.ex examples/bash_files/if_then_else.sh inspect

# Test complex pipelines with JSON output
mix run lib/bash_cli.ex examples/bash_files/redirections_pipelines.sh json

# Test loops with round-trip conversion
mix run lib/bash_cli.ex examples/bash_files/loops.sh round_trip

# Test complex real-world script
mix run lib/bash_cli.ex examples/bash_files/complex_real_world.sh
```

## Comprehensive Testing

Run the comprehensive test file to test all examples:

```bash
mix run examples/comprehensive_examples.exs
```

## Example Output

### Pretty Print output:
```
Script
    └─ Pipeline (3)
       ├─ └─ ls -la
       ├─ └─ grep txt
       └─ └─ wc -l
```

### Inspect output (detailed AST structure):
```
=== Script AST ===
Commands: [%BashInterpreter.AST.Pipeline{
  commands: [%BashInterpreter.AST.Command{...}],
  source_info: %BashInterpreter.AST.SourceInfo{text: "ls -la | grep txt | wc -l"}
}]
```

### Round Trip output:
The input bash script reconstructed from the AST with proper formatting.