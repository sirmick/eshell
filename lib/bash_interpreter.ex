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
  def pretty_print(ast_node, _opts \\ []) do
    BashInterpreter.ASTWalker.walk(ast_node, BashInterpreter.Walkers.PrettyPrintWalker)
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
