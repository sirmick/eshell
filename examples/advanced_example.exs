#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/bash_interpreter/ebin")
# If running directly from the project directory without compiling
Code.prepend_path("lib")

# Import the BashInterpreter module
alias BashInterpreter

IO.puts("Advanced Bash Interpreter Example")
IO.puts("================================\n")

# Example 1: If-then-else conditional
script1 = """
if test -f file.txt; then
  echo "File exists"
else
  echo "File does not exist"
fi
"""
IO.puts("Script:")
IO.puts(script1)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast1 = BashInterpreter.parse(script1)

IO.puts(BashInterpreter.pretty_print(ast1))
IO.puts("\n")

# Example 2: For loop
script2 = """
for file in file1.txt file2.txt file3.txt; do
  cat $file
  echo "---"
done
"""
IO.puts("Script:")
IO.puts(script2)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast2 = BashInterpreter.parse(script2)

IO.puts(BashInterpreter.pretty_print(ast2))
IO.puts("\n")

# Example 3: While loop
script3 = """
while test $count -lt 10; do
  echo $count
  count=$((count + 1))
done
"""
IO.puts("Script:")
IO.puts(script3)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast3 = BashInterpreter.parse(script3)

IO.puts(BashInterpreter.pretty_print(ast3))
IO.puts("\n")

# Example 4: Complex script with nested structures
script4 = """
if grep -q "pattern" file.txt; then
  echo "Pattern found"
  for line in $(grep "pattern" file.txt); do
    echo "Found: $line"
  done
else
  echo "Pattern not found"
  while read -r line; do
    echo "Line: $line"
  done < file.txt
fi
"""
IO.puts("Script:")
IO.puts(script4)
IO.puts("\nAST:")

# Parse the script to generate the AST
ast4 = BashInterpreter.parse(script4)

IO.puts(BashInterpreter.pretty_print(ast4))
IO.puts("\n")