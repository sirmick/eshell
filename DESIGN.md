# Bash-like Syntax Interpreter Design

## Overview

This document outlines the design for a bash-like syntax interpreter implemented in Elixir. The interpreter parses bash-like commands and generates an Abstract Syntax Tree (AST) that represents the structure of the commands.

## Goals

- Create a lexer that tokenizes bash-like input
- Define AST structures to represent bash commands and control structures
- Implement a parser that builds an AST from tokens
- Support nested structures (conditionals, loops, pipelines)
- Provide a clean, extensible design
- Support round-trip conversion (bash → AST → bash)
- Implement source information tracking for accurate reproduction

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
- `:command_substitution` - Dollar-parenthesis command substitution (`$(command)`)
- `:pipe` - Pipe operator (`|`)
- `:redirect_output` - Output redirection (`>`)
- `:redirect_append` - Append redirection (`>>`)
- `:redirect_input` - Input redirection (`<`)
- `:semicolon` - Command separator (`;`)
- `:newline` - Newline characters
- `:lparen`, `:rparen` - Parentheses for subshells
- `:lbrace`, `:rbrace` - Braces for command blocks

**Special Handling:**
- Quoted strings (both single and double quotes) with proper escaping
- Keywords (if, then, else, fi, for, while, do, done, in, until, elif)
- Command substitution with balanced parentheses
- Variable recognition
- Context-aware token classification
- Nested structure keywords

### 2. AST Walker Framework

A generic walker pattern that allows different traversal strategies:

- Pretty printing walker for human-readable output
- JSON walker for serialization and debugging  
- Round-trip walker for reproducing original bash syntax
- Extensible design for adding new walkers

### 3. AST Structures

The AST represents the parsed bash commands and control structures.

**Core Structures:**
- `Script` - A sequence of commands with source information
- `Command` - A simple command with name, arguments, redirections and source info
- `Pipeline` - A sequence of commands connected by pipes
- `Redirect` - Input/output redirection with type information
- `Conditional` - If/then/else structure with proper nesting
- `Loop` - For/while loops with body and condition handling
- `Assignment` - Variable assignment with optional command substitution
- `Subshell` - Commands executed in a subshell

### 4. Parser

The parser converts tokens into an AST. It uses recursive descent parsing to handle nested structures.

**Key Parsing Functions:**
- `parse_commands` - Parse a sequence of commands separated by semicolons/newlines
- `parse_command` - Parse a simple command with arguments and redirections
- `parse_pipeline` - Parse a pipeline of commands connected by pipes
- `parse_conditional` - Parse if/then/else structures with proper nesting
- `parse_for_loop` - Parse for loops with variable iteration
- `parse_while_loop` - Parse while loops with command conditions
- `parse_redirections` - Parse input/output redirections
- `extract_until_nested` - Handle nested control structures with stack-based tracking

**Advanced Features:**
- Nested structure handling with proper scope and context
- Complex redirection parsing (combined input/output redirections)
- Command substitution integration
- Variable assignment recognition
- Bracket expression parsing for test conditions
- Recursive descent with backtracking for ambiguous constructs

### 5. Source Information System

**SourceInfo Structure:**
- Stores complete source text and position information
- Enables round-trip conversion by preserving original formatting
- Tracks line and column positions for debugging
- Supports exact reproduction mode vs. synthesized output

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
  redirects: [%Redirect{type: :output, target: "output.txt", source_info: %SourceInfo{}}],
  source_info: %SourceInfo{}
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
    %Command{name: "ls", args: ["-la"], redirects: [], source_info: %SourceInfo{}},
    %Command{name: "grep", args: [".ex"], redirects: [], source_info: %SourceInfo{}},
    %Command{name: "wc", args: ["-l"], redirects: [], source_info: %SourceInfo{}}
  ],
  source_info: %SourceInfo{}
}
```

### Conditional Parsing

Conditionals use the `if`, `then`, `else`, `fi` keywords with proper nesting.

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
  condition: %Command{name: "test", args: ["-f", "file.txt"], redirects: [], source_info: %SourceInfo{}},
  then_branch: %Script{
    commands: [%Command{name: "echo", args: ["File exists"], redirects: [], source_info: %SourceInfo{}}],
    source_info: %SourceInfo{}
  },
  else_branch: %Script{
    commands: [%Command{name: "echo", args: ["File does not exist"], redirects: [], source_info: %SourceInfo{}}],
    source_info: %SourceInfo{}
  },
  source_info: %SourceInfo{}
}
```

### Loop Parsing

Loops use the `for`/`while`, `do`, `done` keywords with proper nesting.

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
    commands: [%Command{name: "echo", args: ["Processing $file"], redirects: [], source_info: %SourceInfo{}}],
    source_info: %