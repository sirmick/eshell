defmodule BashInterpreter.ASTWalker do
  @moduledoc """
  AST Walker abstraction for traversing and transforming AST nodes.

  This module provides a generic walker pattern that can be used to implement
  different traversal strategies like round-trip conversion and pretty printing.
  """

  alias BashInterpreter.AST

  @doc """
  Walks an AST node with the given walker implementation.

  The walker implementation should be a module that implements the walk/2 function
  for each AST node type.
  """
  def walk(ast_node, walker_module, opts \\ []) do
    case ast_node do
      %AST.Script{} -> walker_module.walk_script(ast_node, opts)
      %AST.Command{} -> walker_module.walk_command(ast_node, opts)
      %AST.Pipeline{} -> walker_module.walk_pipeline(ast_node, opts)
      %AST.Redirect{} -> walker_module.walk_redirect(ast_node, opts)
      %AST.Conditional{} -> walker_module.walk_conditional(ast_node, opts)
      %AST.Loop{} -> walker_module.walk_loop(ast_node, opts)
      %AST.Assignment{} -> walker_module.walk_assignment(ast_node, opts)
      %AST.Subshell{} -> walker_module.walk_subshell(ast_node, opts)
      _ -> walker_module.walk_default(ast_node, opts)
    end
  end

  @doc """
  Walks a list of AST nodes with the given walker implementation.
  """
  def walk_list(nodes, walker_module, opts \\ []) do
    Enum.map(nodes, fn node -> walk(node, walker_module, opts) end)
  end
end
