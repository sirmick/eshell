defmodule BashInterpreter.Executor do
  @moduledoc """
  Executor for the bash interpreter.
  
  This module provides different execution modes for the AST:
  - :pretty_print - Pretty prints the AST (already implemented in BashInterpreter)
  - :serialize - Serializes the AST back to bash syntax
  - :eager - Executes the commands (to be implemented)
  """
  
  alias BashInterpreter.AST
  
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
  
  def execute(_ast, :eager, _opts) do
    raise "Eager execution mode is not implemented yet"
  end
  
  @doc """
  Serializes the AST back to bash syntax.
  """
  def serialize(%AST.Script{} = script) do
    script.commands
    |> Enum.map(&serialize_command/1)
    |> Enum.join("\n")
  end
  
  # Serialize different AST node types
  defp serialize_command(%AST.Command{} = command) do
    args_str = Enum.join(command.args, " ")
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
    then_branch = serialize(%{conditional.then_branch | commands: conditional.then_branch.commands})
    
    if conditional.else_branch do
      else_branch = serialize(%{conditional.else_branch | commands: conditional.else_branch.commands})
      "if #{serialize_command(conditional.condition)}; then\n  #{then_branch}\nelse\n  #{else_branch}\nfi"
    else
      "if #{serialize_command(conditional.condition)}; then\n  #{then_branch}\nfi"
    end
  end
  
  defp serialize_command(%AST.Loop{type: :for} = loop) do
    items = Enum.join(loop.condition.items, " ")
    body = serialize(%{loop.body | commands: loop.body.commands})
    
    "for #{loop.condition.variable} in #{items}; do\n  #{body}\ndone"
  end
  
  defp serialize_command(%AST.Loop{type: :while} = loop) do
    body = serialize(%{loop.body | commands: loop.body.commands})
    
    "while #{serialize_command(loop.condition)}; do\n  #{body}\ndone"
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
end