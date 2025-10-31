# Bash-like Syntax Interpreter Design

## Overview

This document outlines the design for a bash-like syntax interpreter implemented in Elixir. The interpreter parses bash-like commands and generates an Abstract Syntax Tree (AST) that represents the structure of the commands.

## Goals

- Create a lexer that tokenizes bash-like input
- Define AST structures to represent bash commands and control structures
- Implement a parser that builds an AST from tokens
- Support nested structures (conditionals, loops, pipelines)
- Provide a clean, extensible design

## Non-Goals

- Executing the commands (this is just a parser)
- Supporting all bash features (focus on core syntax)
- Performance optimization (focus on correctness and clarity)

## Components

### 1. Lexer

The lexer converts input text into a stream of tokens. Each token has a type and a value.

**Token Types:**
- `:command` - Command names
- `:string` - String literals and arguments
- `:option` - Command options (starting with `-`)
- `:variable` - Environment variables (starting with `$`)
- `:pipe` - Pipe operator (`|`)
- `:redirect_output` - Output redirection (`>`)
- `:redirect_append` - Append redirection (`>>`)
- `:redirect_input` - Input redirection (`<`)
- `:semicolon` - Command separator (`;`)
- `:lparen`, `:rparen` - Parentheses for subshells
- `:lbrace`, `:rbrace` - Braces for command blocks

**Special Handling:**
- Quoted strings (both single and double quotes)
- Keywords (if, then, else, fi, for, while, do, done, etc.)

### 2. AST Structures

The AST represents the parsed bash commands and control structures.

**Core Structures:**
- `Script` - A sequence of commands
- `Command` - A simple command with name, arguments, and redirections
- `Pipeline` - A sequence of commands connected by pipes
- `Redirect` - Input/output redirection
- `Conditional` - If/then/else structure
- `Loop` - For/while loops
- `Assignment` - Variable assignment
- `Subshell` - Commands executed in a subshell

### 3. Parser

The parser converts tokens into an AST. It uses recursive descent parsing to handle nested structures.

**Key Parsing Functions:**
- `parse_commands` - Parse a sequence of commands
- `parse_command` - Parse a simple command
- `parse_pipeline` - Parse a pipeline of commands
- `parse_conditional` - Parse if/then/else structures
- `parse_loop` - Parse for/while loops
- `parse_redirections` - Parse input/output redirections

**Handling Nested Structures:**
- The parser must track context to handle nested structures
- Each control structure has a clear beginning and end marker
- The parser should maintain proper nesting levels

## Parsing Approach

### Command Parsing

Commands are the basic building blocks. A command consists of:
- A command name
- Zero or more arguments
- Zero or more redirections

Example:
```bash
echo hello > output.txt
```

AST:
```elixir
%Command{
  name: "echo",
  args: ["hello"],
  redirects: [%Redirect{type: :output, target: "output.txt"}]
}
```

### Pipeline Parsing

Pipelines connect multiple commands with the pipe operator (`|`).

Example:
```bash
ls -la | grep .ex | wc -l
```

AST:
```elixir
%Pipeline{
  commands: [
    %Command{name: "ls", args: ["-la"], redirects: []},
    %Command{name: "grep", args: [".ex"], redirects: []},
    %Command{name: "wc", args: ["-l"], redirects: []}
  ]
}
```

### Conditional Parsing

Conditionals use the `if`, `then`, `else`, `fi` keywords.

Example:
```bash
if test -f file.txt; then
  echo "File exists"
else
  echo "File does not exist"
fi
```

AST:
```elixir
%Conditional{
  condition: %Command{name: "test", args: ["-f", "file.txt"], redirects: []},
  then_branch: %Script{
    commands: [%Command{name: "echo", args: ["File exists"], redirects: []}]
  },
  else_branch: %Script{
    commands: [%Command{name: "echo", args: ["File does not exist"], redirects: []}]
  }
}
```

### Loop Parsing

Loops use the `for`/`while`, `do`, `done` keywords.

Example:
```bash
for file in *.txt; do
  echo "Processing $file"
done
```

AST:
```elixir
%Loop{
  type: :for,
  condition: %{variable: "file", items: ["*.txt"]},
  body: %Script{
    commands: [%Command{name: "echo", args: ["Processing $file"], redirects: []}]
  }
}
```


## Challenges and Considerations

### 1. Nested Structures

Handling nested structures requires careful tracking of context. For example:

```bash
if test -f file.txt; then
  for line in $(cat file.txt); do
    echo "Line: $line"
  done
else
  echo "File not found"
fi
```

The parser must correctly handle the nesting of the `for` loop inside the `if` statement, and each node must have the correct source information.

### 2. Quoted Strings

Quoted strings require special handling in the lexer. Both single and double quotes should be supported, and quotes within quotes (escaped) should be handled correctly. The source information must include the quotes.

### 3. Variable Expansion

While the parser doesn't need to perform variable expansion, it should correctly identify variables in the input and preserve their exact formatting.

### 4. Error Handling

The parser should provide meaningful error messages for syntax errors. This includes:
- Unclosed quotes
- Missing keywords (e.g., `then` without a matching `fi`)
- Invalid command syntax


## Implementation Strategy

1. Define the AST structures to represent bash commands
2. Implement the Lexer to tokenize input
3. Create the Parser to build AST from tokens
4. Develop the Serializer to convert AST back to bash
5. Add execution modes for different operations
6. Create comprehensive tests for all components
7. Update documentation to explain the functionality

## Testing Strategy

1. Unit tests for the lexer
2. Unit tests for the parser
3. Unit tests for the serializer
4. Round-trip tests for basic functionality
5. Tests for edge cases (nested structures, complex commands)

## Execution Modes

The interpreter now supports multiple execution modes:

1. **Pretty Print Mode**: Visualizes the AST in a human-readable format
2. **Serialization Mode**: Converts the AST back to bash syntax
3. **Eager Mode** (not implemented yet): Will execute the commands

## Round Trip Testing

The interpreter includes round trip testing to verify that bash syntax can be parsed into an AST and then serialized back to equivalent bash syntax. The serialized output may have different formatting than the original input, but it should be functionally equivalent.

## Future Extensions

1. **Source Preservation**: Implement source tracking to preserve exact whitespace from the original source code
2. **Add support for more bash features**:
   - Functions
   - Subshells
   - Command substitution
   - Arithmetic expansion
3. **Implement an executor to run the commands**:
   - Support for executing commands in a controlled environment
   - Variable expansion
   - Exit code handling
4. **Add support for bash builtins**:
   - cd, echo, export, etc.
5. **Enhance error reporting and recovery**:
   - Better error messages
   - Recovery from syntax errors