defmodule BashInterpreter.RoundTripExactTest do
  use ExUnit.Case

  @moduledoc """
  Tests for exact round-trip conversion: bash -> AST -> bash (exact match)

  These tests verify that the round-trip conversion produces the exact
  original source text, not just functionally equivalent text.
  """

  test "simple command exact round trip" do
    input = "echo hello"
    assert_exact_round_trip(input)
  end

  test "command with options exact round trip" do
    input = "ls -la"
    assert_exact_round_trip(input)
  end

  test "pipeline exact round trip" do
    input = "ls -la | grep .ex"
    assert_exact_round_trip(input)
  end

  test "output redirection exact round trip" do
    input = "echo hello > output.txt"
    assert_exact_round_trip(input)
  end

  test "append redirection exact round trip" do
    input = "echo hello >> output.txt"
    assert_exact_round_trip(input)
  end

  test "input redirection exact round trip" do
    input = "cat < input.txt"
    assert_exact_round_trip(input)
  end

  test "multiple redirections exact round trip" do
    input = "cat < input.txt > output.txt"
    assert_exact_round_trip(input)
  end

  test "if statement exact round trip" do
    input = "if test -f file.txt; then echo found; fi"
    assert_exact_round_trip(input)
  end

  test "if-else statement exact round trip" do
    input = "if test -f file.txt; then echo found; else echo not found; fi"
    assert_exact_round_trip(input)
  end

  test "for loop exact round trip" do
    input = "for file in file1.txt file2.txt; do echo $file; done"
    assert_exact_round_trip(input)
  end

  test "while loop exact round trip" do
    input = "while test $count -lt 10; do echo $count; done"
    assert_exact_round_trip(input)
  end

  test "multiline script exact round trip" do
    input = """
    if test -f file.txt; then
      echo "File exists"
    else
      echo "File does not exist"
    fi
    """
    assert_exact_round_trip(input)
  end

  test "complex script exact round trip" do
    input = """
    if grep -q "pattern" file.txt; then
      echo "Pattern found"
      for line in $(grep "pattern" file.txt); do
        echo "Found: $line"
      done
    else
      echo "Pattern not found"
    fi
    """
    assert_exact_round_trip(input)
  end

  defp assert_exact_round_trip(input) do
    # Parse input to AST
    ast = BashInterpreter.parse(input)

    # Get a pretty-printed version of the AST
    pretty_ast = BashInterpreter.execute(ast, :pretty_print)

    # Perform round-trip conversion
    output = BashInterpreter.round_trip(ast)

    # Print info even if test passes
    IO.puts("\n=== Round Trip Exact Test ===")
    IO.puts("Input: #{inspect(input)}")
    IO.puts("\nAST:\n#{pretty_ast}")

    # Check if round-trip matches exactly
    matches = output == input
    IO.puts("\nExact Round Trip: #{if matches, do: "✓ YES", else: "✗ NO"}")

    if !matches do
      IO.puts("\nOutput: #{inspect(output)}")
      IO.puts("\nDifference:")

      # Show character-by-character difference for debugging
      input_chars = String.codepoints(input)
      output_chars = String.codepoints(output)

      diff = Enum.with_index(input_chars)
      |> Enum.map(fn {char, idx} ->
        if idx < length(output_chars) do
          output_char = Enum.at(output_chars, idx)
          if char != output_char do
            "#{char}(#{idx}) != #{output_char}(#{idx})"
          else
            nil
          end
        else
          "#{char}(#{idx}) missing in output"
        end
      end)
      |> Enum.filter(& &1)
      |> Enum.join(", ")

      IO.puts("#{diff}")
    end

    # Assert exact match still for the test to pass/fail
    assert output == input, """
    Round-trip failed! Expected exact match but got different output.
    See details above.
    """
  end
end
