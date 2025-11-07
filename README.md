# Bash Interpreter in Elixir

This is an Elixir library for parsing bash-like syntax into an abstract syntax tree (AST). It demonstrates how to build a parser for a shell-like language.

## Current Status

This project is a **proof of concept** that demonstrates the basic structure of a bash-like syntax interpreter. The current implementation:

- ✅ Has a working lexer that tokenizes bash input
- ✅ Defines AST structures for representing bash commands
- ✅ Implements basic command and pipeline parsing
- ✅ Supports redirections
- ✅ Implements conditionals and loops
- ✅ Supports serialization of AST back to bash syntax
- ✅ Includes round trip testing (bash -> AST -> bash)
- ❌ Does not execute the commands

See [DESIGN.md](DESIGN.md) for a detailed specification of the intended functionality.

## Features

- Lexical analysis of bash-like syntax
- Parsing into a structured AST
- Support for basic commands and arguments
- Support for pipes and redirections
- Simplified representation of conditionals (if/else)
- Simplified representation of loops (for/while)
- Pretty printing of the AST
- Serialization of AST back to bash syntax
- Multiple execution modes (pretty print, serialize)

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

# Parse a pipeline
ast = BashInterpreter.parse("ls -la | grep .ex")

# Pretty print the AST
IO.puts(BashInterpreter.pretty_print(ast))

# Serialize the AST back to bash
bash = BashInterpreter.serialize(ast)
IO.puts(bash)

# Execute the AST using a specific mode
BashInterpreter.execute(ast, :pretty_print)  # Pretty print mode
BashInterpreter.execute(ast, :serialize)     # Serialize mode
```


## Examples

Check out the `examples` directory for more detailed examples:

- `basic_example.exs`: Demonstrates parsing of simple commands, arguments, and pipes
- `advanced_example.exs`: Demonstrates simplified parsing of conditionals and loops
- `round_trip_example.exs`: Demonstrates round-trip conversions (bash -> AST -> bash)

To run an example:

```bash
cd bash_interpreter
mix compile
elixir -pa _build/dev/lib/bash_interpreter/ebin examples/basic_example.exs
```

## Project Structure

- `lib/bash_interpreter.ex`: Main module providing the public API
- `lib/bash_interpreter/lexer.ex`: Tokenizes bash input
- `lib/bash_interpreter/ast.ex`: Defines AST structures
- `lib/bash_interpreter/parser.ex`: Builds AST from tokens
- `lib/bash_interpreter/executor.ex`: Handles execution modes and serialization
- `test/`: Unit and integration tests
- `examples/`: Example scripts demonstrating usage

## Future Work

To make this a fully functional bash interpreter, the following would need to be implemented:

1. **Execution**: Implement an executor to actually run the commands
2. **Execution**: Implement an executor to actually run the commands
3. **Error Handling**: Enhance error detection and reporting
4. **Additional Features**: Support for functions, subshells, variable expansion, etc.
5. **Bash Builtins**: Support for bash builtin commands like cd, echo, export, etc.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
