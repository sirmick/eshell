defmodule BashInterpreter.ParserTest do
  use ExUnit.Case
  doctest BashInterpreter.Parser

  alias BashInterpreter.Parser
  alias BashInterpreter.AST

  test "parses a simple command" do
    input = "echo hello"
    result = Parser.parse(input)
    assert %AST.Script{commands: [command]} = result
    assert command.name == "echo"
    assert command.args == ["hello"]
    assert command.redirects == []
  end

  test "parses a command with options" do
    input = "ls -la"
    result = Parser.parse(input)
    assert %AST.Script{commands: [command]} = result
    assert command.name == "ls"
    assert command.args == ["-la"]
    assert command.redirects == []
  end

  test "parses a pipeline" do
    input = "ls -la | grep .ex"
    result = Parser.parse(input)
    assert %AST.Script{commands: [pipeline]} = result
    assert %AST.Pipeline{commands: [cmd1, cmd2]} = pipeline
    
    assert cmd1.name == "ls"
    assert cmd1.args == ["-la"]
    assert cmd1.redirects == []
    
    assert cmd2.name == "grep"
    assert cmd2.args == [".ex"]
    assert cmd2.redirects == []
  end

  test "parses multiple commands" do
    input = "cd /tmp; ls -la; echo message"
    result = Parser.parse(input)
    assert %AST.Script{commands: [cmd1, cmd2, cmd3]} = result
    
    assert cmd1.name == "cd"
    assert cmd1.args == ["/tmp"]
    assert cmd1.redirects == []
    
    assert cmd2.name == "ls"
    assert cmd2.args == ["-la"]
    assert cmd2.redirects == []
    
    assert cmd3.name == "echo"
    assert cmd3.args == ["message"]
    assert cmd3.redirects == []
  end

  test "parses output redirection" do
    input = "echo hello > output.txt"
    result = Parser.parse(input)
    assert %AST.Script{commands: [command]} = result
    
    assert command.name == "echo"
    assert command.args == ["hello"]
    assert length(command.redirects) == 1
    
    [redirect] = command.redirects
    assert redirect.type == :output
    assert redirect.target == "output.txt"
  end

  test "parses append redirection" do
    input = "echo hello >> output.txt"
    result = Parser.parse(input)
    assert %AST.Script{commands: [command]} = result
    
    assert command.name == "echo"
    assert command.args == ["hello"]
    assert length(command.redirects) == 1
    
    [redirect] = command.redirects
    assert redirect.type == :append
    assert redirect.target == "output.txt"
  end

  test "parses input redirection" do
    input = "cat < input.txt"
    result = Parser.parse(input)
    assert %AST.Script{commands: [command]} = result
    
    assert command.name == "cat"
    assert command.args == []
    assert length(command.redirects) == 1
    
    [redirect] = command.redirects
    assert redirect.type == :input
    assert redirect.target == "input.txt"
  end

  test "parses if statement" do
    input = "if test -f file.txt; then echo found; fi"
    result = Parser.parse(input)
    
    # With the updated parser, if statements are now properly parsed as a single conditional
    assert %AST.Script{commands: commands} = result
    assert length(commands) == 1
    
    # Command should be a conditional
    conditional = List.first(commands)
    assert %AST.Conditional{} = conditional
    
    # Check condition
    assert %AST.Command{name: "test", args: ["-f", "file.txt"]} = conditional.condition
    
    # Check then branch
    assert %AST.Script{commands: then_commands} = conditional.then_branch
    assert length(then_commands) == 1
    assert %AST.Command{name: "echo", args: ["found"]} = List.first(then_commands)
    
    # Check that else branch is nil
    assert is_nil(conditional.else_branch)
  end

  test "parses if-else statement" do
    input = "if test -f file.txt; then echo found; else echo not found; fi"
    result = Parser.parse(input)
    
    # With the updated parser, if-else statements are now properly parsed as a single conditional
    assert %AST.Script{commands: commands} = result
    assert length(commands) == 1
    
    # Command should be a conditional
    conditional = List.first(commands)
    assert %AST.Conditional{} = conditional
    
    # Check condition
    assert %AST.Command{name: "test", args: ["-f", "file.txt"]} = conditional.condition
    
    # Check then branch
    assert %AST.Script{commands: then_commands} = conditional.then_branch
    assert length(then_commands) == 1
    assert %AST.Command{name: "echo", args: ["found"]} = List.first(then_commands)
    
    # Check else branch
    assert %AST.Script{commands: else_commands} = conditional.else_branch
    assert length(else_commands) == 1
    assert %AST.Command{name: "echo", args: ["not", "found"]} = List.first(else_commands)
  end

  test "parses for loop" do
    input = "for file in file1.txt file2.txt; do echo $file; done"
    result = Parser.parse(input)
    
    # With the updated parser, for loops are now properly parsed as a single loop
    assert %AST.Script{commands: commands} = result
    assert length(commands) == 1
    
    # Command should be a loop
    loop = List.first(commands)
    assert %AST.Loop{type: :for} = loop
    
    # Check condition
    assert %{variable: "file", items: items} = loop.condition
    assert items == ["file1.txt", "file2.txt"]
    
    # Check body
    assert %AST.Script{commands: body_commands} = loop.body
    assert length(body_commands) == 1
    assert %AST.Command{name: "echo", args: ["$file"]} = List.first(body_commands)
  end

  test "parses while loop" do
    input = "while test $count -lt 10; do echo $count; done"
    result = Parser.parse(input)
    
    # With the updated parser, while loops are now properly parsed as a single loop
    assert %AST.Script{commands: commands} = result
    assert length(commands) == 1
    
    # Command should be a loop
    loop = List.first(commands)
    assert %AST.Loop{type: :while} = loop
    
    # Check condition
    assert %AST.Command{name: "test", args: ["$count", "-lt", "10"]} = loop.condition
    
    # Check body
    assert %AST.Script{commands: body_commands} = loop.body
    assert length(body_commands) == 1
    assert %AST.Command{name: "echo", args: ["$count"]} = List.first(body_commands)
  end
end