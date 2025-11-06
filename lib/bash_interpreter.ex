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
      iex> String.contains?(result, "echo hello")
      true
  """
  def pretty_print(ast_node, opts \\ []) do
    BashInterpreter.ASTWalker.walk(ast_node, BashInterpreter.Walkers.PrettyPrintWalker)
  end

  @doc """
  Gets JSON representation of an AST for debugging.

  ## Examples

      iex> ast = BashInterpreter.parse("echo hello")
      iex> json = BashInterpreter.to_json(ast)
      iex> String.contains?(json, "\\\"name\\\":\\\"echo\\\"")
      true
  """
  def to_json(ast_node, opts \\ []) do
    BashInterpreter.Walkers.JSONWalker.to_json(ast_node, opts)
  end

  @doc """
  Prints JSON representation of an AST to console for debugging.

  This is useful for debugging the AST structure and understanding how
  the parser represents different bash constructs.
  """
  def debug(ast_node, opts \\ []) do
    json = to_json(ast_node, opts)
    IO.puts("AST JSON:")
    IO.puts(json)
    IO.puts("")
    json
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
      iex> String.contains?(result, "echo hello")
      true

      iex> ast = BashInterpreter.parse("echo hello")
      iex> BashInterpreter.execute(ast, :serialize)
      "echo hello"
  """
  def execute(ast, mode \\ :json, opts \\ []) do
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
