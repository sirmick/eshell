defmodule BashInterpreter.Executor do
  @moduledoc """
  Executor for the bash interpreter.

  This module provides different execution modes for the AST:
  - :pretty_print - Pretty prints the AST (already implemented in BashInterpreter)
  - :serialize - Serializes the AST back to bash syntax
  - :round_trip - Uses source_info to reproduce the original source text
  - :eager - Executes the commands (to be implemented)
  """

  alias BashInterpreter.AST
  alias BashInterpreter.ASTWalker
  alias BashInterpreter.Walkers.RoundTripWalker

  @doc """
  Executes the AST using the specified mode.

  ## Modes
  - :pretty_print - Pretty prints the AST
  - :serialize - Serializes the AST back to bash syntax
  - :eager - Executes the commands (not implemented yet)

  ## Examples

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.Executor.execute(ast, :pretty_print)
      "Script:\\n  Command: echo\\n    Args: [\\"hello\\"]\\n    Redirects: []"

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.Executor.execute(ast, :serialize)
      "echo hello"
  """
  def execute(ast, mode \\ :pretty_print, opts \\ [])

  def execute(ast, :pretty_print, _opts) do
    BashInterpreter.pretty_print(ast)
  end

  def execute(ast, :serialize, _opts) do
    serialize(ast)
  end

  def execute(ast, :round_trip, opts) do
    # Pass the :exact option to ensure source_info is preferred
    ASTWalker.walk(ast, RoundTripWalker, [exact: true] ++ opts)
  end

  def execute(_ast, :eager, _opts) do
    raise "Eager execution mode is not implemented yet"
  end

  @doc """
  Serializes the AST back to bash syntax.
  """
  def serialize(%AST.Script{} = script) do
    script.commands
    |> Enum.map(&serialize_command/1)
    |> Enum.join("; ")
  end

  # Serialize different AST node types
  defp serialize_command(%AST.Command{} = command) do
    # Convert each arg to string, handling the case where an arg is a Command struct
    args_str = command.args
      |> Enum.map(fn
        arg when is_binary(arg) ->
          # Handle quoted strings outside of guard clauses
          if String.contains?(arg, " ") do
            # Preserve quotes from the original source if possible
            # (using source_info would be ideal here, but we'll use a simple approach)
            # Handle already quoted strings
            if String.starts_with?(arg, "\"") and String.ends_with?(arg, "\"") do
              arg
            else
              ~s("#{arg}")
            end
          else
            arg
          end
        %AST.Command{} = cmd -> serialize_command(cmd)
        arg -> to_string(arg)
      end)
      |> Enum.join(" ")

    redirects_str = Enum.map(command.redirects, &serialize_redirect/1) |> Enum.join(" ")

    [command.name, args_str, redirects_str]
    |> Enum.filter(fn s -> s != "" end)
    |> Enum.join(" ")
  end

  defp serialize_command(%AST.Pipeline{} = pipeline) do
    pipeline.commands
    |> Enum.map(&serialize_command/1)
    |> Enum.join(" | ")
  end

  defp serialize_command(%AST.Conditional{} = conditional) do
    # Format the then branch with proper indentation
    then_branch_str = conditional.then_branch.commands
       |> Enum.map(&serialize_command/1)
       |> Enum.join("\n")
       |> indent_lines()

    # Handle else branch if it exists, with proper indentation
    if conditional.else_branch do
      else_branch_str = conditional.else_branch.commands
         |> Enum.map(&serialize_command/1)
         |> Enum.join("\n")
         |> indent_lines()

      "if #{serialize_command(conditional.condition)}; then\n#{then_branch_str}\nelse\n#{else_branch_str}\nfi"
    else
      "if #{serialize_command(conditional.condition)}; then\n#{then_branch_str}\nfi"
    end
  end

  defp serialize_command(%AST.Loop{type: :for} = loop) do
    # Format the body with proper indentation
    body_str = loop.body.commands
        |> Enum.map(&serialize_command/1)
        |> Enum.join("\n")
        |> indent_lines()

    items = Enum.join(loop.condition.items, " ")
    "for #{loop.condition.variable} in #{items}; do\n#{body_str}\ndone"
  end

  defp serialize_command(%AST.Loop{type: :while} = loop) do
    # Format the body with proper indentation
    body_str = loop.body.commands
        |> Enum.map(&serialize_command/1)
        |> Enum.join("\n")
        |> indent_lines()

    "while #{serialize_command(loop.condition)}; do\n#{body_str}\ndone"
  end

  defp serialize_command(%AST.Assignment{} = assignment) do
    "#{assignment.name}=#{assignment.value}"
  end

  defp serialize_command(%AST.Subshell{} = subshell) do
    body = serialize(subshell.script)
    "(#{body})"
  end

  defp serialize_redirect(%AST.Redirect{type: :output} = redirect) do
    "> #{redirect.target}"
  end

  defp serialize_redirect(%AST.Redirect{type: :append} = redirect) do
    ">> #{redirect.target}"
  end

  defp serialize_redirect(%AST.Redirect{type: :input} = redirect) do
    "< #{redirect.target}"
  end

  # Helper to indent each line of text
  defp indent_lines(text) do
    text
    |> String.split("\n")
    |> Enum.map(fn line -> if String.trim(line) != "", do: "  #{line}", else: line end)
    |> Enum.join("\n")
  end
end
