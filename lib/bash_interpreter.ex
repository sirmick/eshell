defmodule BashInterpreter do
  @moduledoc """
  BashInterpreter is a library for parsing and interpreting bash-like syntax.

  It provides functionality to parse bash commands into an abstract syntax tree (AST)
  that can be used for further processing or execution.
  """

  alias BashInterpreter.Lexer
  alias BashInterpreter.Parser
  alias BashInterpreter.AST
  alias BashInterpreter.Executor

  @doc """
  Parses a string of bash commands into an AST.

  ## Examples

      iex> script = BashInterpreter.parse("echo hello")
      iex> script.commands |> hd() |> Map.get(:name)
      "echo"
      iex> script.commands |> hd() |> Map.get(:args)
      ["hello"]
  """
  def parse(input, _opts \\ []) when is_binary(input) do
    Parser.parse(input)
  end

  @doc """
  Tokenizes a string of bash commands into a list of tokens.
  This is mainly useful for debugging or understanding the parsing process.

  ## Examples

      iex> BashInterpreter.tokenize("echo hello")
      [{:command, "echo"}, {:string, "hello"}]
  """
  def tokenize(input, _opts \\ []) when is_binary(input) do
    Lexer.tokenize(input)
  end

  @doc """
  Pretty prints an AST for easier visualization.

  ## Examples

      iex> result = "echo hello" |> BashInterpreter.parse() |> BashInterpreter.pretty_print()
      iex> String.contains?(result, "Command: echo")
      true
  """
  def pretty_print(%AST.Script{} = script) do
    "Script:\n" <> (
      script.commands
      |> Enum.map(&pretty_print_command(&1, 2))
      |> Enum.join("\n")
    )
  end

  defp pretty_print_command(%AST.Command{} = command, indent) do
    spaces = String.duplicate(" ", indent)
    args_str = inspect(command.args)
    redirects_str = inspect(command.redirects)

    "#{spaces}Command: #{command.name}\n" <>
    "#{spaces}  Args: #{args_str}\n" <>
    "#{spaces}  Redirects: #{redirects_str}"
  end

  defp pretty_print_command(%AST.Pipeline{} = pipeline, indent) do
    spaces = String.duplicate(" ", indent)
    commands_str = pipeline.commands
                   |> Enum.map(&pretty_print_command(&1, indent + 2))
                   |> Enum.join("\n")

    "#{spaces}Pipeline:\n#{commands_str}"
  end

  defp pretty_print_command(%AST.Conditional{} = conditional, indent) do
    spaces = String.duplicate(" ", indent)

    # Print the condition with actual arguments
    condition_str = case conditional.condition do
      %AST.Command{name: name, args: args, redirects: redirects} ->
        "#{spaces}  Command: #{name}\n" <>
        "#{spaces}    Args: #{inspect(args)}\n" <>
        "#{spaces}    Redirects: #{inspect(redirects)}"
      other ->
        pretty_print_command(other, indent + 2)
    end

    # Print the then branch
    then_str = pretty_print(conditional.then_branch)
                |> String.split("\n")
                |> Enum.map(fn line -> "#{spaces}  #{line}" end)
                |> Enum.join("\n")

    # Print the else branch if it exists
    else_str = if conditional.else_branch do
      else_branch = pretty_print(conditional.else_branch)
                    |> String.split("\n")
                    |> Enum.map(fn line -> "#{spaces}  #{line}" end)
                    |> Enum.join("\n")
      "\n#{spaces}Else:\n#{else_branch}"
    else
      ""
    end

    "#{spaces}If:\n" <>
    "#{spaces}Condition:\n#{condition_str}\n" <>
    "#{spaces}Then:\n#{then_str}#{else_str}"
  end

  defp pretty_print_command(%AST.Loop{} = loop, indent) do
    spaces = String.duplicate(" ", indent)

    # Print the condition based on loop type
    condition_str = case loop.type do
      :for ->
        var = loop.condition.variable
        items = inspect(loop.condition.items)
        "#{spaces}  Variable: #{var}\n#{spaces}  Items: #{items}"

      :while ->
        # For while loops, print the condition command with actual arguments
        case loop.condition do
          %AST.Command{name: name, args: args, redirects: redirects} ->
            "#{spaces}  Command: #{name}\n" <>
            "#{spaces}    Args: #{inspect(args)}\n" <>
            "#{spaces}    Redirects: #{inspect(redirects)}"
          other ->
            pretty_print_command(other, indent + 2)
        end
    end

    # Print the body
    body_str = pretty_print(loop.body)
               |> String.split("\n")
               |> Enum.map(fn line -> "#{spaces}  #{line}" end)
               |> Enum.join("\n")

    "#{spaces}#{String.capitalize(to_string(loop.type))} Loop:\n" <>
    "#{spaces}Condition:\n#{condition_str}\n" <>
    "#{spaces}Body:\n#{body_str}"
  end

  defp pretty_print_command(%AST.Assignment{} = assignment, indent) do
    spaces = String.duplicate(" ", indent)

    "#{spaces}Assignment:\n" <>
    "#{spaces}  Name: #{assignment.name}\n" <>
    "#{spaces}  Value: #{assignment.value}"
  end

  defp pretty_print_command(%AST.Subshell{} = subshell, indent) do
    spaces = String.duplicate(" ", indent)

    script_str = pretty_print(subshell.script)
                 |> String.split("\n")
                 |> Enum.map(fn line -> "#{spaces}  #{line}" end)
                 |> Enum.join("\n")

    "#{spaces}Subshell:\n#{script_str}"
  end

  @doc """
  Executes the AST using the specified mode.

  ## Modes
  - :pretty_print - Pretty prints the AST
  - :serialize - Serializes the AST back to bash syntax
  - :eager - Executes the commands (not implemented yet)

  ## Examples

      iex> ast = BashInterpreter.parse("echo hello")
      iex> result = BashInterpreter.execute(ast, :pretty_print)
      iex> String.contains?(result, "Command: echo")
      true

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.execute(ast, :serialize)
      "echo hello"
  """
  def execute(ast, mode \\ :pretty_print, opts \\ []) do
    Executor.execute(ast, mode, opts)
  end

  @doc """
  Serializes the AST back to bash syntax.

  ## Examples

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.serialize(ast)
      "echo hello"
  """
  def serialize(ast) do
    Executor.serialize(ast)
  end

  @doc """
  Performs a round-trip conversion using source_info to reproduce the original source text.

  ## Examples

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.round_trip(ast)
      "echo hello"
  """
  def round_trip(ast) do
    Executor.execute(ast, :round_trip)
  end
end
