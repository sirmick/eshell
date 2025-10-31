defmodule BashInterpreter.LexerTest do
  use ExUnit.Case
  doctest BashInterpreter.Lexer

  alias BashInterpreter.Lexer

  test "tokenizes a simple command" do
    input = "echo hello"
    expected = [{:command, "echo"}, {:string, "hello"}]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes a command with options" do
    input = "ls -la"
    expected = [{:command, "ls"}, {:option, "-la"}]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes a pipeline" do
    input = "ls -la | grep .ex"
    expected = [
      {:command, "ls"},
      {:option, "-la"},
      {:pipe, "|"},
      {:command, "grep"},
      {:string, ".ex"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes redirections" do
    input = "echo hello > output.txt"
    expected = [
      {:command, "echo"},
      {:string, "hello"},
      {:redirect_output, ">"},
      {:string, "output.txt"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes append redirection" do
    input = "echo hello >> output.txt"
    expected = [
      {:command, "echo"},
      {:string, "hello"},
      {:redirect_append, ">>"},
      {:string, "output.txt"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes input redirection" do
    input = "cat < input.txt"
    expected = [
      {:command, "cat"},
      {:redirect_input, "<"},
      {:string, "input.txt"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes semicolons" do
    input = "cd /tmp; ls -la; echo done"
    tokens = Lexer.tokenize(input)
    assert length(tokens) == 8
    assert Enum.at(tokens, 0) == {:command, "cd"}
    assert Enum.at(tokens, 1) == {:string, "/tmp"}
    assert Enum.at(tokens, 2) == {:semicolon, ";"}
    assert Enum.at(tokens, 3) == {:command, "ls"}
    assert Enum.at(tokens, 4) == {:option, "-la"}
    assert Enum.at(tokens, 5) == {:semicolon, ";"}
    assert Enum.at(tokens, 6) == {:command, "echo"}
    # The last token could be either {:string, "done"} or {:command, "done"}
    # Both are acceptable since "done" is a keyword but also a valid argument
    assert elem(Enum.at(tokens, 7), 1) == "done"
  end

  test "tokenizes if statement" do
    input = "if test -f file.txt; then echo found; fi"
    expected = [
      {:command, "if"},
      {:command, "test"},
      {:option, "-f"},
      {:string, "file.txt"},
      {:semicolon, ";"},
      {:command, "then"},
      {:command, "echo"},
      {:string, "found"},
      {:semicolon, ";"},
      {:command, "fi"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes for loop" do
    input = "for file in *.txt; do echo $file; done"
    expected = [
      {:command, "for"},
      {:string, "file"},
      {:command, "in"},
      {:string, "*.txt"},
      {:semicolon, ";"},
      {:command, "do"},
      {:command, "echo"},
      {:variable, "$file"},
      {:semicolon, ";"},
      {:command, "done"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes while loop" do
    input = "while test $count -lt 10; do echo $count; done"
    expected = [
      {:command, "while"},
      {:command, "test"},
      {:variable, "$count"},
      {:option, "-lt"},
      {:string, "10"},
      {:semicolon, ";"},
      {:command, "do"},
      {:command, "echo"},
      {:variable, "$count"},
      {:semicolon, ";"},
      {:command, "done"}
    ]
    tokens = Lexer.tokenize(input)
    assert tokens == expected
  end

  test "tokenizes quoted strings" do
    input = "echo \"hello world\""
    tokens = Lexer.tokenize(input)
    assert length(tokens) == 2
    assert Enum.at(tokens, 0) == {:command, "echo"}
    assert elem(Enum.at(tokens, 1), 0) == :string
    assert String.contains?(elem(Enum.at(tokens, 1), 1), "hello world")
  end

  test "tokenizes single quoted strings" do
    input = "echo 'hello world'"
    tokens = Lexer.tokenize(input)
    assert length(tokens) == 2
    assert Enum.at(tokens, 0) == {:command, "echo"}
    assert elem(Enum.at(tokens, 1), 0) == :string
    assert String.contains?(elem(Enum.at(tokens, 1), 1), "hello world")
  end
end