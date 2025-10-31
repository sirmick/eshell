#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/bash_interpreter/ebin")
# If running directly from the project directory without compiling
Code.prepend_path("lib")

# Import the BashInterpreter module
alias BashInterpreter

IO.puts("Bash Redirections Example")
IO.puts("========================\n")

# Example 1: Output redirection
script1 = "echo Hello > output.txt"
IO.puts("Script: #{script1}")
IO.puts("\nAST:")
ast1 = BashInterpreter.parse(script1)
IO.puts(BashInterpreter.pretty_print(ast1))
IO.puts("\n")

# Example 2: Append redirection
script2 = "echo World >> output.txt"
IO.puts("Script: #{script2}")
IO.puts("\nAST:")
ast2 = BashInterpreter.parse(script2)
IO.puts(BashInterpreter.pretty_print(ast2))
IO.puts("\n")

# Example 3: Input redirection
script3 = "cat < input.txt"
IO.puts("Script: #{script3}")
IO.puts("\nAST:")
ast3 = BashInterpreter.parse(script3)
IO.puts(BashInterpreter.pretty_print(ast3))
IO.puts("\n")

# Example 4: Multiple redirections
script4 = "cat < input.txt > output.txt"
IO.puts("Script: #{script4}")
IO.puts("\nAST:")
ast4 = BashInterpreter.parse(script4)
IO.puts(BashInterpreter.pretty_print(ast4))
IO.puts("\n")

# Example 5: Redirections with pipelines
script5 = "cat < input.txt | grep pattern > results.txt"
IO.puts("Script: #{script5}")
IO.puts("\nAST:")
ast5 = BashInterpreter.parse(script5)
IO.puts(BashInterpreter.pretty_print(ast5))
IO.puts("\n")

# Example 6: Redirections with command sequences
script6 = """
echo "Start" > log.txt
cat file.txt >> log.txt
echo "End" >> log.txt
"""
IO.puts("Script:")
IO.puts(script6)
IO.puts("\nAST:")
ast6 = BashInterpreter.parse(script6)
IO.puts(BashInterpreter.pretty_print(ast6))
IO.puts("\n")

# Example 7: Redirections with loops
script7 = """
for file in *.txt; do
  cat $file >> all_files.txt
done
"""
IO.puts("Script:")
IO.puts(script7)
IO.puts("\nAST:")
ast7 = BashInterpreter.parse(script7)
IO.puts(BashInterpreter.pretty_print(ast7))
IO.puts("\n")

# Example 8: Redirections with conditionals
script8 = """
if test -f file.txt; then
  cat file.txt > output.txt
else
  echo "File not found" > error.log
fi
"""

# Parse the script to generate the AST
ast8 = BashInterpreter.parse(script8)

IO.puts("Script:")
IO.puts(script8)
IO.puts("\nAST:")
IO.puts(BashInterpreter.pretty_print(ast8))
IO.puts("\n")