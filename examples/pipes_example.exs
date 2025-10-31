#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/bash_interpreter/ebin")
# If running directly from the project directory without compiling
Code.prepend_path("lib")

# Import the BashInterpreter module
alias BashInterpreter

IO.puts("Bash Pipes Example")
IO.puts("=================\n")

# Example 1: Simple pipe
script1 = "ls -la | grep .ex"
IO.puts("Script: #{script1}")
IO.puts("\nAST:")
ast1 = BashInterpreter.parse(script1)
IO.puts(BashInterpreter.pretty_print(ast1))
IO.puts("\n")

# Example 2: Multiple pipes
script2 = "cat file.txt | grep pattern | wc -l"
IO.puts("Script: #{script2}")
IO.puts("\nAST:")
ast2 = BashInterpreter.parse(script2)
IO.puts(BashInterpreter.pretty_print(ast2))
IO.puts("\n")

# Example 3: Pipes with redirections
script3 = "cat < input.txt | grep pattern | sort > output.txt"
IO.puts("Script: #{script3}")
IO.puts("\nAST:")
ast3 = BashInterpreter.parse(script3)
IO.puts(BashInterpreter.pretty_print(ast3))
IO.puts("\n")

# Example 4: Pipes in conditionals
script4 = """
if cat file.txt | grep -q pattern; then
  echo "Pattern found"
else
  echo "Pattern not found"
fi
"""
IO.puts("Script:")
IO.puts(script4)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast4 = BashInterpreter.parse(script4)

IO.puts(BashInterpreter.pretty_print(ast4))
IO.puts("\n")

# Example 5: Pipes in loops
script5 = """
for file in *.txt; do
  cat $file | grep pattern | wc -l
done
"""
IO.puts("Script:")
IO.puts(script5)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast5 = BashInterpreter.parse(script5)

IO.puts(BashInterpreter.pretty_print(ast5))
IO.puts("\n")

# Example 6: Complex pipeline with subshells
script6 = "cat file.txt | (grep pattern | sort) | uniq -c"
IO.puts("Script: #{script6}")
IO.puts("\nAST:")

# Parse the script to generate the AST
ast6 = BashInterpreter.parse(script6)

IO.puts(BashInterpreter.pretty_print(ast6))
IO.puts("\n")