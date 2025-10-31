# Bash Interpreter - TODO List

## Parser Improvements

- [ ] Complete parser implementation for conditionals (if/then/else) without relying on hardcoded examples
- [ ] Complete parser implementation for loops (for/while) without relying on hardcoded examples
- [ ] Implement proper parsing for subshells and command substitution
- [ ] Add support for variable expansion in the parser
- [ ] Improve error handling and reporting in the parser

## Lexer Enhancements

- [ ] Add support for more bash-specific tokens and keywords
- [ ] Enhance handling of quoted strings and escaping
- [ ] Implement whitespace preservation for accurate source code representation
- [ ] Add support for comments in bash scripts

## AST Refinements

- [ ] Extend AST structures to support more bash features
- [ ] Add support for functions and function calls
- [ ] Implement proper handling of environment variables
- [ ] Add support for arithmetic operations

## Executor Implementation

- [ ] Implement the eager execution mode to actually run commands
- [ ] Add support for bash builtins (cd, echo, export, etc.)
- [ ] Implement environment variable handling during execution
- [ ] Add support for exit codes and command status

## Testing Improvements

- [ ] Replace simplified assertions in parser tests with full AST structure validation
- [ ] Add more comprehensive tests for edge cases
- [ ] Create tests for error handling and recovery
- [ ] Add benchmarks for performance testing

## Documentation

- [ ] Add more detailed documentation for each module
- [ ] Create a comprehensive user guide
- [ ] Add examples for all supported features
- [ ] Document limitations and known issues

## Examples Cleanup

- [ ] Replace hardcoded AST examples with actual parsed results
- [ ] Add more realistic and complex examples
- [ ] Create examples that demonstrate all supported features
- [ ] Add examples showing error handling and recovery

## Future Features

- [ ] Add support for bash functions
- [ ] Implement proper handling of environment variables
- [ ] Add support for bash arrays
- [ ] Implement process management for background jobs
- [ ] Add support for signal handling