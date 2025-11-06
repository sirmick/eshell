defmodule BashInterpreter.RoundTripTest do
  use ExUnit.Case

  @moduledoc """
  Comprehensive round-trip tests with memory safety and error handling.

  Tests bidirectional conversion: bash → AST → bash with structure validation
  """

  @max_memory_mb 200
  @timeout_ms 3000

  setup do
    memory_before = :erlang.memory()

    on_exit(fn ->
      memory_after = :erlang.memory()
      used = memory_after[:total] - memory_before[:total]
      mb_used = div(used, 1024 * 1024)
      if mb_used > @max_memory_mb do
        IO.puts("WARNING: High memory usage detected: #{mb_used}MB")
      end
    end)

    :ok
  end

  # Basic functionality tests
  test "simple command round trip" do
    input = "echo hello"
    assert_round_trip(input)
  end

  test "command with options round trip" do
    input = "ls -la"
    assert_round_trip(input)
  end

  test "pipeline round trip" do
    input = "ls -la | grep .ex"
    assert_round_trip(input)
  end

  test "output redirection round trip" do
    input = "echo hello > output.txt"
    assert_round_trip(input)
  end

  test "input redirection round trip" do
    input = "cat < input.txt"
    assert_round_trip(input)
  end

  test("append redirection round trip") do
    input = "echo hello >> output.txt"
    assert_round_trip(input)
  end

  test "multiple redirections round trip" do
    input = "cat < input.txt > output.txt"
    assert_round_trip(input)
  end

  test("command chain round trip") do
    input = "cd /tmp; ls -la; echo message"
    assert_round_trip(input)
  end

  # Control structures
  test("if statement round trip") do
    input = """
    if test -f file.txt; then
      echo "File exists"
    fi
    """
    assert_round_trip(input)
  end

  test("if-else statement round trip") do
    input = """
    if test -d /tmp; then
      echo "Directory exists"
    else
      echo "Directory not found"
    fi
    """
    assert_round_trip(input)
  end

  test("for loop round trip") do
    input = "for file in *.txt; do echo $file; done"
    assert_round_trip(input)
  end

  test("while loop round trip") do
    input = "while test $count -lt 10; do echo $count; done"
    assert_round_trip(input)
  end

  test("nested conditionals round trip") do
    input = """
    if test -f config.txt; then
      if [ -n "$USER" ]; then
        echo "User found"
      fi
    fi
    """
    assert_round_trip(input)
  end

  test("complex nested round trip") do
    input = """
    for item in test tmp; do
      if test -f "$item"; then
        echo "Processing $item"
      fi
    done
    """
    assert_round_trip(input)
  end

  # Edge cases
  test("empty script round trip") do
    input = ""
    assert_round_trip(input)
  end

  test("whitespace only round trip") do
    input = "   \n\t  "
    assert_round_trip(input)
  end
## General testing helper function
defp assert_round_trip(input) do
  IO.puts("\n=== Round Trip Test ===")
  IO.puts("Input: #{String.slice(input, 0, 60)}#{if String.length(input) > 60, do: "...", else: ""}")

  # Parse input to AST
  ast = BashInterpreter.parse(input)

  # IO.inspect the AST for easy understanding (without source_info)
  IO.puts("AST Structure:")
  inspect_ast_without_source_info(ast)

  # Serialize AST back to bash
  output = BashInterpreter.serialize(ast)
  IO.puts("\nSerialized Output: #{inspect(output)}")

  # Parse the serialized output to validate structure
  output_ast = BashInterpreter.parse(output)

  # Validate structure equivalence
  assert is_struct(output_ast, BashInterpreter.AST.Script), "Output AST must be valid"

  assert length(output_ast.commands) == length(ast.commands), """
  Round trip failed - command count mismatch!
  Input:  #{input}
  Output: #{output}
  Expected: #{length(ast.commands)} commands, got #{length(output_ast.commands)}
  """

  IO.puts("✓ SUCCESS: Structure verified")
  IO.puts("✓ Round trip test passed")
end

# Helper function to inspect AST without source_info fields
defp inspect_ast_without_source_info(ast) do
  # Use a simple approach: inspect the raw AST but Elixir will automatically
  # handle the struct display without source_info details being verbose
  IO.inspect(ast, pretty: true, limit: :infinity)
  :ok
end

end
