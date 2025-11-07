# Bash Interpreter in Elixir

This is an Elixir library for parsing bash-like syntax into an abstract syntax tree (AST). It demonstrates how to build a parser for a shell-like language with round-trip conversion capabilities.

## Current Status

This project is a **proof of concept** that demonstrates the basic structure of a bash-like syntax interpreter. The current implementation:

- ✅ Has a working lexer that tokenizes bash input with comprehensive support for quotes, variables, and special characters
- ✅ Defines AST structures for representing bash commands with source information tracking
- ✅ Implements basic command and pipeline parsing with proper nesting support
- ✅ Supports redirections (input, output, append) with combined redirection handling
- ✅ Implements sophisticated conditionals and loops with proper nested structure handling
- ✅ Supports serialization of AST back to bash syntax with formatting preservation
- ✅ Includes round trip testing with source information preservation
- ✅ Provides comprehensive AST walker framework for extensible processing
- ❌ Does not execute the commands

See [DESIGN.md](DESIGN.md) for a detailed specification of the intended functionality.

## Key Features

- **Comprehensive Lexical Analysis**: Tokenizes bash-like syntax with support for quoted strings, variables, pipes, redirections, and control structures
- **Structured Parsing**: Converts tokens into a comprehensive AST supporting complex nested structures
- **Advanced Command Support**: Pipes, redirections, command substitution, variable assignment
- **Control Structures**: Complete support for conditionals (if/then/else) and loops (for/while) with proper nesting
- **AST Walker Framework**: Extensible pattern for implementing different processing modes (pretty print, JSON, round-trip)
- **Source Information Tracking**: Preserves original source text and formatting for accurate reproduction
- **Multiple Execution Modes**: Pretty printing, serialization, round-trip conversion
- **Comprehensive Testing**: Round-trip validation ensures parsing correctness

## Installation

Add `bash_interpreter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bash_interpreter, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
# Parse a simple command
ast = BashInterpreter.parse("echo hello")

# Tokenize for debugging
tokens = BashInterpreter.tokenize("ls -la | grep .ex")

# Parse a pipeline
ast = BashInterpreter.parse("ls -la | grep .ex")

# Parse conditionals and loops
ast = BashInterpreter.parse("if test -f file.txt; then echo found; fi")
ast = BashInterpreter.parse("for file in *.txt; do echo $file; done")

# Pretty print the AST
IO.puts(BashInterpreter.pretty_print(ast))

# Serialize the AST back to bash
bash = BashInterpreter.serialize(ast)
IO.puts(bash)

# Get JSON representation for debugging
json = BashInterpreter.to_json(ast)

# Execute the AST using a specific mode
BashInterpreter.execute(ast, :pretty_print)   # Pretty print mode
BashInterpreter.execute(ast, :serialize)      # Serialize mode
BashInterpreter.execute(ast, :round_trip)       # Round-trip mode

# Round-trip conversion (preserves original formatting when possible)
original_bash = "echo hello"
parsed_ast = BashInterpreter.parse(original_bash)
reconstructed_bash = BashInterpreter.round_trip(parsed_ast)
```

## Examples

The project includes comprehensive examples in the repository:

### Basic Examples:
```elixir
# Basic commands
parsed = BashInterpreter.parse("echo hello world ls")

# Pipelines  
parsed = BashInterpreter.parse("cat file.txt | grep pattern | wc -l")

# Commands with options
parsed = BashInterpreter.parse("ls -la /home/user")
```

### Advanced Examples:
```elixir
# Nested conditionals
script = """
if test -f config.txt; then
  echo "Config exists"
  for item in $(cat config.txt); do
    echo "Processing $item"
  done
else
  echo "No config"
fi
"""
parsed = BashInterpreter.parse(script)

# While loops with redirections
script = """
while test -s queue.txt; do
  process_item < queue.txt > output.log
done
"""
parsed = BashInterpreter.parse(script)
```

Check out the `examples` directory for more detailed examples:

- `basic_example.exs`: Demonstrates parsing of simple commands, arguments, and pipes
- `advanced_example.exs`: Demonstrates parsing of conditionals and loops  
- `round_trip_example.exs`: Demonstrates round-trip conversions (bash -> AST -> bash)

To run an example:

```bash
cd bash_interpreter
mix compile
elixir -pa _build/dev/lib/bash_interpreter/ebin examples/basic_example.exs
```

## Project Structure

```
lib/
├── bash_interpreter.ex              # Main module providing the public API
├── bash_interpreter/
    ├── ast.ex                      # Defines AST structures
    ├── ast_walker.ex               # Generic AST traversal framework
    ├── lexer.ex                    # Tokenizes bash input
    ├── parser.ex                   # Builds AST from tokens
    ├── executor.ex                 # Handles execution modes
    ├── ast/
    │   └── source_info.ex          # Source position tracking
    └── walkers/
        ├── pretty_print_walker.ex  # Pretty print walker
        ├── json_walker.ex         # JSON serialization walker
        └── round_trip_walker.ex   # Round-trip walker
test/                              # Unit and integration tests
examples/                          # Example scripts and usage demos
```

## Architecture Highlights

### Lexer Features:
- **Context-aware tokenization**: Distinguishes commands from arguments based on position
- **Quote handling**: Supports single/double quotes with proper escaping
- **Command substitution**: Handles `$(command)` patterns with balanced parentheses
- **Variable recognition**: Identifies `$VARIABLE` patterns
- **Nested structure keywords**: Tracks control flow keywords for parsing

### Parser Features:
- **Recursive descent parsing**: Handles nested structures correctly
- **Source information preservation**: Maintains original text and formatting
- **Complex redirection support**: Handles combined input/output redirections
- **Nested control structures**: Properly handles for loops inside if statements, etc.
- **Command substitution integration**: Parses command substitutions into the AST

### AST Walker Framework:
- **Generic traversal pattern**: Allows different processing modes
- **Extensible design**: Easy to add new walkers
- **Source-preserving**: Round-trip walker can reproduce original formatting
- **Pretty printing**: Clean ASCII tree output for debugging

### Testing Validation:
- **Round-trip testing**: Ensures bash → AST → bash conversion accuracy
- **Structural validation**: Verifies command, argument, and redirection parsing
- **Memory safety**: Tests include memory usage monitoring
- **Edge case coverage**: Tests unclosed strings, malformed structures

## Supported Bash Constructs

### Commands & Pipelines:
```bash
# Basic commands
echo hello world
ls -la /tmp
cat file.txt

# Pipelines  
ls | grep pattern | wc -l
find /src -name "*.ex" | xargs grep "TODO"
```

### Redirections:
```bash
# Output redirection
echo "hello" > output.txt
echo "append" >> output.txt

# Input redirection
cat < input.txt
grep pattern < file.txt > results.txt

# Combined redirections
cat < in.txt > out.txt
```

### Control Structures:
```bash
# If/then/else (single and multi-line)
if test -f file.txt; then echo "exists"; fi
if [ -d /tmp ]; then
  echo "directory exists"
else
  echo "directory not found"
fi

# For loops (with proper iteration)
for file in *.txt; do echo "Processing $file"; done

# While loops
while test -s queue.txt; do
  process_item
done
```

### Complex Nested Structures:
```bash
# Nested conditionals
if test -f config.txt; then
  echo "Config exists"
  if [ -n "$USER" ]; then
    echo "User set"
  fi
fi

# Loops within conditionals
if test -d /tmp; then
  for item in log backup cache; do
    echo "Checking $item"
  done
fi
```

## Future Work

To make this a fully functional bash interpreter, the following would need to be implemented:

1. **Command Execution**: Implement a command executor to actually run the parsed bash syntax
2. **Variable Expansion**: Support runtime variable expansion and environment variable handling
3. **Additional Features**: 
   - Functions and function calls
   - Arithmetic expansion and expressions
   - Command substitution execution
   - Subshell execution contexts
4. **Bash Builtins**: Support for built-in commands like `cd`, `echo`, `export`, `source`, etc.
5. **Error Handling**: Enhanced syntax error detection with line/column information
6. **Performance Optimization**: Stream processing for large bash scripts
7. **Extended Control Structures**: Support for `case`/`esac`, `select`, `until`, function definitions

## License

This project is licensed under the MIT License - see the LICENSE file for details.
