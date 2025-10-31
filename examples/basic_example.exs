#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/bash_interpreter/ebin")
# If running directly from the project directory without compiling
Code.prepend_path("lib")

# Import the BashInterpreter module
alias BashInterpreter

IO.puts("Basic Bash Interpreter Example")
IO.puts("==============================\n")

# Example 1: Simple command
script1 = "echo Hello, World!"
IO.puts("Script: #{script1}")
ast1 = BashInterpreter.parse(script1)
IO.puts("AST:")
IO.puts(BashInterpreter.pretty_print(ast1))
IO.puts("\n")

# Example 2: Command with arguments
script2 = "ls -la /tmp"
IO.puts("Script: #{script2}")
ast2 = BashInterpreter.parse(script2)
IO.puts("AST:")
IO.puts(BashInterpreter.pretty_print(ast2))
IO.puts("\n")

# Example 3: Pipeline
script3 = "cat file.txt | grep pattern | wc -l"
IO.puts("Script: #{script3}")
ast3 = BashInterpreter.parse(script3)
IO.puts("AST:")
IO.puts(BashInterpreter.pretty_print(ast3))
IO.puts("\n")

# Example 4: Command with redirections
script4 = "echo log message > output.log"
IO.puts("Script: #{script4}")
ast4 = BashInterpreter.parse(script4)
IO.puts("AST:")
IO.puts(BashInterpreter.pretty_print(ast4))
IO.puts("\n")

# Example 5: Multiple commands
script5 = "cd /tmp; ls -la; echo done"
IO.puts("Script: #{script5}")
ast5 = BashInterpreter.parse(script5)
IO.puts("AST:")
IO.puts(BashInterpreter.pretty_print(ast5))
IO.puts("\n")