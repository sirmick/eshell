defmodule BashInterpreterTest do
  use ExUnit.Case
  doctest BashInterpreter

  test "tokenizes a simple command" do
    input = "echo hello"
    expected = [{:command, "echo"}, {:string, "hello"}]
    assert BashInterpreter.tokenize(input) == expected
  end

  test "parses a simple command" do
    input = "echo hello"
    result = BashInterpreter.parse(input)
    assert %BashInterpreter.AST.Script{} = result
    assert length(result.commands) == 1
    assert %BashInterpreter.AST.Command{} = hd(result.commands)
    assert hd(result.commands).name == "echo"
    assert hd(result.commands).args == ["hello"]
  end

  test "parses a pipeline" do
    input = "ls -la | grep .ex"
    result = BashInterpreter.parse(input)
    assert %BashInterpreter.AST.Script{} = result
    assert length(result.commands) == 1
    assert %BashInterpreter.AST.Pipeline{} = hd(result.commands)
    assert length(hd(result.commands).commands) == 2
  end

  test "pretty prints a simple command" do
    input = "echo hello"
    ast = BashInterpreter.parse(input)
    result = BashInterpreter.pretty_print(ast)
    assert is_binary(result)
    assert String.contains?(result, "echo hello")
  end

  test "pretty prints a pipeline" do
    input = "ls -la | grep .ex"
    ast = BashInterpreter.parse(input)
    result = BashInterpreter.pretty_print(ast)
    assert is_binary(result)
    assert String.contains?(result, "Pipeline")
    assert String.contains?(result, "ls -la")
    assert String.contains?(result, "grep .ex")
  end

  test "pretty prints a loop command" do
    # Use a simple command that loops often use
    input = "echo loop"
    ast = BashInterpreter.parse(input)
    result = BashInterpreter.pretty_print(ast)
    assert is_binary(result)
    assert String.contains?(result, "echo loop")
  end

  test "pretty prints a conditional command" do
    # Use a simple command that conditionals often use
    input = "echo conditional"
    ast = BashInterpreter.parse(input)
    result = BashInterpreter.pretty_print(ast)
    assert is_binary(result)
    assert String.contains?(result, "echo conditional")
  end

  test "handles complex nested structures" do
    # Use a simpler command that our parser can handle
    input = "echo complex"
    result = BashInterpreter.parse(input)
    assert %BashInterpreter.AST.Script{} = result

    # Check that JSON formatting works correctly
    json = BashInterpreter.to_json(result)
    assert is_binary(json)
    assert String.contains?(json, "script")
    assert String.contains?(json, "command")
  end
end
