#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.prepend_path("_build/dev/lib/bash_interpreter/ebin")
# If running directly from the project directory without compiling
Code.prepend_path("lib")

# Import the BashInterpreter module
alias BashInterpreter

IO.puts("Bash Round Trip Example")
IO.puts("======================\n")

# Example 1: Simple command
script1 = "echo hello"
IO.puts("Original: #{script1}")
ast1 = BashInterpreter.parse(script1)
serialized1 = BashInterpreter.serialize(ast1)
IO.puts("Serialized: #{serialized1}")
IO.puts("\n")

# Example 2: Pipeline
script2 = "ls -la | grep .ex | wc -l"
IO.puts("Original: #{script2}")
ast2 = BashInterpreter.parse(script2)
serialized2 = BashInterpreter.serialize(ast2)
IO.puts("Serialized: #{serialized2}")
IO.puts("\n")

# Example 3: Redirections
script3 = "cat < input.txt > output.txt"
IO.puts("Original: #{script3}")
ast3 = BashInterpreter.parse(script3)
serialized3 = BashInterpreter.serialize(ast3)
IO.puts("Serialized: #{serialized3}")
IO.puts("\n")

# Example 4: If statement
script4 = """
if test -f file.txt; then
  echo "File exists"
fi
"""
IO.puts("Original:")
IO.puts(script4)
ast4 = BashInterpreter.parse(script4)
serialized4 = BashInterpreter.serialize(ast4)
IO.puts("Serialized:")
IO.puts(serialized4)
IO.puts("\n")

# Example 5: For loop
script5 = """
for file in *.txt; do
  cat $file
done
"""
IO.puts("Original:")
IO.puts(script5)
ast5 = BashInterpreter.parse(script5)
serialized5 = BashInterpreter.serialize(ast5)
IO.puts("Serialized:")
IO.puts(serialized5)
IO.puts("\n")

# Example 6: While loop
script6 = """
while test $count -lt 10; do
  echo $count
done
"""
IO.puts("Original:")
IO.puts(script6)
ast6 = BashInterpreter.parse(script6)
serialized6 = BashInterpreter.serialize(ast6)
IO.puts("Serialized:")
IO.puts(serialized6)
IO.puts("\n")

# Example 7: Complex script
script7 = """
if grep -q "pattern" file.txt; then
  echo "Pattern found"
  for line in $(grep "pattern" file.txt); do
    echo "Found: $line"
  done
else
  echo "Pattern not found"
fi
"""
IO.puts("Original:")
IO.puts(script7)
ast7 = BashInterpreter.parse(script7)
serialized7 = BashInterpreter.serialize(ast7)
IO.puts("Serialized:")
IO.puts(serialized7)
IO.puts("\n")

# Example 8: Execution modes
script8 = "echo hello > output.txt"
IO.puts("Original: #{script8}")
ast8 = BashInterpreter.parse(script8)

IO.puts("Pretty Print Mode:")
pretty_print = BashInterpreter.execute(ast8, :pretty_print)
IO.puts(pretty_print)

IO.puts("Serialize Mode:")
serialized = BashInterpreter.execute(ast8, :serialize)
IO.puts(serialized)
IO.puts("\n")

# Verify round trip
IO.puts("Round Trip Verification:")
IO.puts("1. Parse original script to AST")
IO.puts("2. Serialize AST back to bash")
IO.puts("3. Parse serialized bash to new AST")
IO.puts("4. Compare ASTs")

# Use a simpler example for verification
original = "echo hello"
IO.puts("\nOriginal: #{original}")

# Step 1: Parse original script to AST
ast = BashInterpreter.parse(original)
IO.puts("AST: #{inspect(ast, pretty: true)}")

# Step 2: Serialize AST back to bash
serialized = BashInterpreter.serialize(ast)
IO.puts("Serialized: #{serialized}")

# Step 3: Parse serialized bash to new AST
new_ast = BashInterpreter.parse(serialized)
IO.puts("New AST: #{inspect(new_ast, pretty: true)}")

# Step 4: Compare ASTs
are_equal = inspect(ast) == inspect(new_ast)
IO.puts("ASTs are equal: #{are_equal}")

# Try another example with a pipeline
IO.puts("\n--- Pipeline Example ---")
pipeline_original = "ls -la | grep .ex"
IO.puts("Original: #{pipeline_original}")

# Step 1: Parse original script to AST
pipeline_ast = BashInterpreter.parse(pipeline_original)
IO.puts("AST: #{inspect(pipeline_ast, pretty: true)}")

# Step 2: Serialize AST back to bash
pipeline_serialized = BashInterpreter.serialize(pipeline_ast)
IO.puts("Serialized: #{pipeline_serialized}")

# Step 3: Parse serialized bash to new AST
pipeline_new_ast = BashInterpreter.parse(pipeline_serialized)
IO.puts("New AST: #{inspect(pipeline_new_ast, pretty: true)}")

# Step 4: Compare ASTs
pipeline_are_equal = inspect(pipeline_ast) == inspect(pipeline_new_ast)
IO.puts("ASTs are equal: #{pipeline_are_equal}")